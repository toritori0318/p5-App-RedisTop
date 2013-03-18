package App::RedisTop::Component::Connection;
use base 'App::RedisTop::Component';
sub new {
    my $class = shift;

    my $self = bless {
        group => 'conn',
        items => [
            { name => 'total/s',   stat_key => 'total_connections_received', diff => 1 },
            { name => 'clients',   stat_key => 'connected_clients', },
        ],
        width => 9,
        unit  => 1,
        total => 1,
        @_,
    }, $class;
}

1;
