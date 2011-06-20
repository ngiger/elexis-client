#import "templates"
#import "nodes"

# Folgende Zeile auskommentieren und anpasse, wenn man einen Debian
# Apt-Cache Server irgendwo im lokalen Netz hat 
# $approx="fest:3142"

$extlookup_datadir = "/home/elexis/extdata"
$extlookup_precedence = ["%{fqdn}", "domain_%{domain}", "common"]
$mail_domain = "mail.praxis.notfound"

node default {

# einige nützlich Packete. Evtl noch gnome oder kde-plasma-desktop hinzufügen.
  package {[ "vim-puppet", "git", "etckeeper"]:  ensure => present, }

  if $approx {
  file { "/etc/apt/apt.conf":
	content => 
"Acquire::http::Proxy \"http://$approx:3142/\";
APT::Default-Release \"$lsbdistcodename\";
"
}
}

  elexis::add_user {"elexis":uid => 1300, email => "arzt@$mail_domain",      ensure => present}
  elexis::add_user {"MPA_1":uid => 1301, email => "gute.seele@$mail_domain",      ensure => present}
  elexis::add_user {"MPA_2":uid => 1302, email => "leider.unfaehig@$mail_domain", ensure => absent}

  file {"/opt/elexis": ensure => directory, }
  elexis::install{"elexis-2.1.5.rc4":
	ensure  => present,
	destdir => "/opt/elexis",
	source => "http://ngiger.dyndns.org/jenkins/view/Elexis%202.1.5/job/elexis-2.1.5.x-ant/18/artifact/deploy/linux/elexis-2.1.5.rc4/*zip*/elexis-2.1.5.rc4.zip",
	version => "2.1.5.rc4",
  }
  include nginx::base
  include dnsmasq::base
  file { "/home/elexis/demo.txt":
	content => "something in it",
      owner => elexis,
      mode  => 0644,
   }

# Aufsetzen der Datenbank (Postgres)
#

    include postgres::client
    include postgres::server
# Creating new cluster (configuration: /etc/postgresql/8.4/main, data: /var/lib/postgresql/8.4/main)...

    postgres::database { "elexisDB":            ensure => present, owner => 'elexis' }

    postgres::role     { 'elexis':  ensure => present}
    postgres::grant    { "psql-grant-elexisDB-to-elexis":  database => 'elexisDB', ensure => present, owner => 'elexis' }

    postgres::role     { "niklaus": ensure => present}
    postgres::grant    { "psql-grant-all-to-niklaus": ensure => present, owner => 'niklaus' }

    postgres::load     { "load-elexis-dump":  database => "elexisDB", dumpFile => "/opt/downloads/demoDB/demoDB.sql"}

}
