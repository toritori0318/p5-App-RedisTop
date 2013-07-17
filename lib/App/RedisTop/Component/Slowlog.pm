package App::RedisTop::Component::Slowlog;
use base 'App::RedisTop::Component';
sub new {
    my $class = shift;

    my $self = bless {
        group => 'slowlog',
        items => [
            { name => 'slowlog', stat_key => 'slowlog_len', },
        ],
        width => 9,
        unit  => 1,
        total => 1,
        @_,
    }, $class;
}

1;
