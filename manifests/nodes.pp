# nodes.pp
#

node 'server.praxis.ch' inherits basenode {
    include postgresql::server
    include mediawiki::server
    include approx::server
}

node 'backup.praxis.ch' inherits basenode {
    include postgresql::server
    include mediawiki::server
    include approx::server
}

node 'x2go.praxis.ch' inherits basenode {
    include x2go::server
}


