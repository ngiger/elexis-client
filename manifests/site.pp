#import "templates"
#import "nodes"

# Folgende Zeile auskommentieren und anpasse, wenn man einen Debian
# Apt-Cache Server irgendwo im lokalen Netz hat 
# $approx="http://fest:3142/"

$extlookup_datadir = "/home/elexis/extdata"
$extlookup_precedence = ["%{fqdn}", "domain_%{domain}", "common"]
$mail_domain = "mail.praxis.notfound"

# Unten korrekte SMTP-IP, Benutzernamen und Passwort angeben, 
$SMTP_OUTPUT="$smtp.hispeed.ch:your.username@hispeed.ch:yourpassword"

# Untenstehende Zeile aktiveren, um Elexis runterzuladen und zu installieren
# $elexis_zip ="http://ngiger.dyndns.org/jenkins/view/Elexis%202.1.5/job/elexis-2.1.5.x-ant/18/artifact/deploy/linux/elexis-2.1.5.rc4/*zip*/elexis-2.1.5.rc4.zip"
# Untenstehende Zeile aktiveren, um den Dump einer Elexis-Datenbank zu holen und zu installieren
# $elexis_dump = "/opt/downloads/demoDB/demoDB.sql"


node default {

#------------------------------------------------------------------------------------------------------------------------
# einige nützlich Packete. Evtl noch gnome oder kde-plasma-desktop hinzufügen.
#------------------------------------------------------------------------------------------------------------------------
package {[ "vim-puppet", "git", "etckeeper"]:  ensure => present, }

#------------------------------------------------------------------------------------------------------------------------
# Benutzer Verwaltung
#------------------------------------------------------------------------------------------------------------------------

# elexis user has UID 1000 if installed by our simple-cdd. Add it only if necessary
#  elexis::add_user {"elexis":uid => 1300, email => "arzt@$mail_domain",      ensure => present }
#  elexis::add_user {"MPA_1":uid => 1301, email => "gute.seele@$mail_domain",      ensure => present}
  elexis::add_user {"MPA_2":uid => 1302, email => "leider.unfaehig@$mail_domain", ensure => absent}

#------------------------------------------------------------------------------------------------------------------------
# get elexis and compile it from source
#------------------------------------------------------------------------------------------------------------------------
  if $elexis_zip {  
      file {"/opt/elexis": ensure => directory, mode => 0775,}
      elexis::install{"elexis-2.1.5.rc4": ensure  => present, destdir => "/opt/elexis",
	source => "$elexis_zip", version => "2.1.5.rc4", }
  }

#------------------------------------------------------------------------------------------------------------------------
# Aufsetzen der Datenbank für Elexis (Postgres)
#------------------------------------------------------------------------------------------------------------------------

    include postgres::client
    include postgres::server
# Creating new cluster (configuration: /etc/postgresql/8.4/main, data: /var/lib/postgresql/8.4/main)...

    postgres::role     { 'elexis':  ensure => present}
    postgres::grant    { "psql-grant-elexisDB-to-elexis":  database => 'elexisDB', ensure => present, owner => 'elexis' }

    postgres::role     { "niklaus": ensure => present}
    postgres::grant    { "psql-grant-all-to-niklaus": ensure => present, owner => 'niklaus' }

    postgres::database { "elexisDB":            ensure => present, owner => 'elexis' }
    if $elexis_dump { postgres::load     { "load-elexis-dump":  database => "elexisDB", dumpFile => $elexis_dump,} }

#------------------------------------------------------------------------------------------------------------------------
# Beispiel für eine beliebige Datei, zB. ein Script, welches vorhanden sein muss
#------------------------------------------------------------------------------------------------------------------------
  file { "/home/elexis/demo.txt":
	content => "something in it",
      owner => elexis,
      mode  => 0644,
   }

#------------------------------------------------------------------------------------------------------------------------
# Fall man mehrere Debian-Systeme zu betreuen hat, lohnt es sich, einen Cache-Server für die Pakete aufzusetzen
#------------------------------------------------------------------------------------------------------------------------

  if $approx {
  file { "/etc/apt/apt.conf":
	content => 
"Acquire::http::Proxy \"$approx/\";
APT::Default-Release \"$lsbdistcodename\";
"
  }
}
#------------------------------------------------------------------------------------------------------------------------
# NGINX, DNSMASQ sind services welche ich gerne gebrauche
#------------------------------------------------------------------------------------------------------------------------

  include nginx::base
  include dnsmasq::base


#------------------------------------------------------------------------------------------------------------------------
# EXIM4-Konfigurieren
#------------------------------------------------------------------------------------------------------------------------

  if $SMTP_OUTPUT {
    file{ "/etc/exim4/passwd.client":
      owner => root,
      group => "Debian-exim",
      mode => 0600,
      content => "$SMTP_OUTPUT",
      require => Package["exim4-config", "exim4-daemon-light"],
    }
    file{ "/etc/exim4/update-exim4.conf.conf":
      owner => root,
      group => "Debian-exim",
      mode => 0644,
      content => "# Debian specifice configuration
dc_eximconfig_configtype='local'
dc_other_hostnames='$fqdn'
dc_local_interfaces='127.0.0.1 ; ::1'
dc_readhost=''
dc_relay_domains=''
dc_minimaldns='false'
dc_relay_nets=''
dc_smarthost=''
CFILEMODE='644'
dc_use_split_config='false'
dc_hide_mailname=''
dc_mailname_in_oh='true'
dc_localdelivery='mail_spool'
",
      require => Package["exim4-config", "exim4-daemon-light"],
      notify  => Exec["update-exim4"],
    }
    exec{"update-exim4":
      command => "/usr/sbin/dpkg-reconfigure --unseen-only exim4-config --priority=high",
      refreshonly => true,
  }
  package { ["exim4", "exim4-config", "exim4-daemon-light"]:
    ensure => present,
  }
}

#------------------------------------------------------------------------------------------------------------------------
# RSYNC setup. Damit die home-Verzeichnisse der Benutzer leicht gesichert werden können
#------------------------------------------------------------------------------------------------------------------------

    package { "rsync":
      ensure => present
    }
    file {"/etc/rsyncd.conf":
      ensure => present,
      content => "
# MODULE OPTIONS
[home]
        comment =  Zugriff auf Heimatverzeichnis
        path = /home
        use chroot = no
        lock file = /var/lock/rsyncd
        read only = yes
        list = yes
	fake super = yes
        strict modes = false
        hosts allow = $network_eth0/24
        ignore errors = no
        ignore nonreadable = yes
        transfer logging = no
        timeout = 600
        refuse options = checksum dry-run
        dont compress = *.gz *.tgz *.zip *.z *.rpm *.deb *.iso *.bz2 *.tbz
",
    owner => root,
    group => root,
    mode => 600,
  }
  augeas{"/etc/default/rsync":
    context => "/files/etc/default/rsync",
    changes => [
       "set RSYNC_ENABLE true",
     ], 
    notify => Service["rsync"],
  }
  service{ "rsync": ensure => running,
    require => [Package["rsync"], File["/etc/rsyncd.conf"]],
    hasrestart => true,
  }
}
