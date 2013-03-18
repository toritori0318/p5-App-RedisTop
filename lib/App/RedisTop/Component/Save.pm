package App::RedisTop::Component::Save;
use base 'App::RedisTop::Component';
sub new {
    my $class = shift;

    my $self = bless {
        group => 'save',
        items => [
            {
                name     => 'changes',
                stat_key => sub {
                    my $redis_version = shift;
                    return $redis_version =~ /^2\.4/
                        ? 'changes_since_last_save'
                        : 'rdb_changes_since_last_save';
                },
            },
           ],
        width => 7,
        unit  => 1,
        total => 1,
        @_,
    }, $class;
}

1;
