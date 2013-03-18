package App::RedisTop::Component::CPU;
use base 'App::RedisTop::Component';
sub new {
    my $class = shift;
    my $self = bless {
        group => 'cpu',
        items => [
            { name => 'sys', stat_key => 'used_cpu_sys',  diff => 1 },
            { name => 'usr', stat_key => 'used_cpu_user', diff => 1 },
        ],
        width => 6,
        round => 1,
        @_,
    }, $class;
}

1;
