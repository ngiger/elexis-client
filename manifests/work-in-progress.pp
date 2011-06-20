# augeas lens for pg_hba seems to have problems and cannot
# be copied 1:1 to squeeze from unstable
#file { '/usr/share/augeas/lenses/dist/pg_hba.aug':
  # Augeas definition for pg_hba.conf
  #source => "modules/postgres/pg_hba.aug",
#  content => "niklaus",
#  owner => root, group => 0, mode => 0755,
#  ensure => present,
#}
# augeas lens for sources does not allow to create new entries!
#  elexis::non-free{"source-non-free":
#	ensure => present,
#	type =>  "deb",
#	uri => "http://security.debian.org/neu",
#	distribution => "squeeze/updates",
#	component1 => "main",
#	component2 => "contrib",
#	component3 => "non-free",
#  }
#  elexis::non-free{"source-non-free2":
#	ensure => present,
#	type => "deb",
#	uri => "http://ftp.ch.debian.org/debian/",
#	component1 => "main",
#	component2 => "contrib",
#	component3 => "non-free",
#  }

# Dies 
#users::lookup {'Gyong':
#    ensure => present, # default value
#    groups => [], # default value
#}

#class user::lookup {
#	realize(User['Gyong'])
#}
#users::lookup {'niklaus':
#    ensure => present, # default value
#    groups => [], # default value
#}

#class user::lookup inherits user::virtual {
#  realize (User['niklaus'] )
#}
   user::managed{"niklausxx":
#
#	ensure => present,
	password => "$6$g2A.4RfT$xBZ1J9C3BNPJTwr.OWnuXfTOEGp3Zw9RXF7KVU6FwCJu53VMZyUJeX0uOVNwa04wSDRHr2vyt9/0VgAW98.LQ1",
	managehome => true,
	# homedir => true,
	}
