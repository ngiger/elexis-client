node elexis-co {
# a few things a  Medelexis OC could use on its server

nginx::redirect{"redmine": ensure => "present", source => "redmine", destination => "http://172.25.1.62/redmine/", }
# apt-cacher-ng is a lot easier to setup (speak does not need any setup) for Ubuntu,Debian
# but we need also approx for simple-cdd 

package {[ "vim-puppet", "git", "etckeeper", "approx", "apt-cacher-ng"]:  ensure => present, }


# following lines needed for elexis-dnsmasq
#dhcp-authoritative
#dhcp-boot=pxelinux.0
#dhcp-boot=pxelinux.0,giger-services,172.25.1.63
#dhcp-option=3,172.25.1.60
#dhcp-option-force=208,f1:00:74:7e
#dhcp-option-force=209,ltsp/i386
#dhcp-option-force=210,/tftpboot/pxelinux/files/
#dhcp-option-force=211,30i
#dhcp-range=eth0,172.25.1.120,172.25.1.150,12h
#domain=ngiger.dyndns.org
#expand-hosts
#interface=eth0


  $tst_host = extlookup("tst_host","tstxx,172.5.1.1,3:4:5")
  dnsmasq::add_host{"tst_host": ensure =>  present, 
	ip     => extlookup("host_ip",  "192.168.1.254"),
	name   => extlookup("host_name", "default"),
	mac_id => "1:3"
	# mac_id => extlookup(“host_mac",  "c8:0a:a9:8e:a7:ff"), 
	}

  dnsmasq::add_host{"ng-hp": ensure =>  present, ip=> "172.25.1.61", mac_id => "c8:0a:a9:8e:a7:dd", name => "ng-hp",}
}