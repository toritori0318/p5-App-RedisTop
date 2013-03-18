package App::RedisTop::Component::DB;
use base 'App::RedisTop::Component';
sub new {
    my $class = shift;

    my $self = bless {
        group => 'db',
        items => [
            { name => 'keys',    stat_key => 'keys', },
            { name => 'expires', stat_key => 'expires', },
        ],
        width => 7,
        unit  => 1,
        total => 1,
        dbid  => 0,
        @_,
    }, $class;
    # set group name
    $self->{group} = $self->{group} . $self->{dbid};
    $self;
}

# override
sub stat_values {
    my ($self, $stat) = @_;
    my @results;
    my $db_key = "db" . $self->{dbid};
    my $value  = $stat->{$db_key} || "keys=0,expires=0";
    my ($keys, $expires) = map {$_ =~ /keys=(\d+),expires=(\d+)/; $1, $2} ($value);
    return ($keys, $expires);
}

1;
