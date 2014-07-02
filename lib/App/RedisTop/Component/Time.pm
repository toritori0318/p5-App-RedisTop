package App::RedisTop::Component::Time;
use base 'App::RedisTop::Component';
use POSIX qw(strftime);

sub new {
    my $class = shift;
    my $self = bless {
        group => 'date/time',
        items => [
            { name => 'time', data => sub { strftime("%m/%d %H:%M:%S", localtime()) }, },
        ],
        width => 15,
        @_,
    }, $class;
}

1;
