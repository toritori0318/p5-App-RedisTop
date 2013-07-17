package App::RedisTop::Component::ConnectionPer;
use base 'App::RedisTop::Component';
sub new {
    my $class = shift;

    my $self = bless {
        group => 'connper',
        items => [
            { name => 'conn/max', stat_key => 'connected_clients', denominator_key => 'maxclients'},
        ],
        width => 9,
        total => 1,
        @_,
    }, $class;
}

1;
