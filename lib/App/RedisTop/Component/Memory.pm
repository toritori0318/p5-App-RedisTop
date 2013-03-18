package App::RedisTop::Component::Memory;
use base 'App::RedisTop::Component';
sub new {
    my $class = shift;

    my $self = bless {
        group => 'mem',
        items => [
            { name => 'use',  stat_key => 'used_memory', },
            { name => 'rss',  stat_key => 'used_memory_rss', },
            { name => 'frag', stat_key => 'mem_fragmentation_ratio', },
        ],
        width => 7,
        unit  => 1,
        @_,
    }, $class;
}

1;
