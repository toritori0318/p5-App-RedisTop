package App::RedisTop::Component::MemoryPer;
use base 'App::RedisTop::Component';
sub new {
    my $class = shift;

    my $self = bless {
        group => 'memper',
        items => [
            { name => 'use/max', stat_key => 'used_memory', denominator_key => 'maxmemory'},
        ],
        width => 8,
        @_,
    }, $class;
}

1;
