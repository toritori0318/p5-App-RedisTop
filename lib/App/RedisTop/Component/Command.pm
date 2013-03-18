package App::RedisTop::Component::Command;
use base 'App::RedisTop::Component';
sub new {
    my $class = shift;

    my $self = bless {
        group => 'command',
        items => [
            { name => 'total/s',  stat_key => 'total_commands_processed', diff => 1 },
            { name => 'hits/s',   stat_key => 'keyspace_hits',   diff => 1 },
            { name => 'misses/s', stat_key => 'keyspace_misses', diff => 1 },
        ],
        width => 8,
        unit  => 1,
        total => 1,
        @_,
    }, $class;
}

1;
