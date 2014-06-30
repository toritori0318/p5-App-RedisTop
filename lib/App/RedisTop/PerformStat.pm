package App::RedisTop::PerformStat;
use Term::ANSIColor qw/colored/;
use List::Util qw/max/;
use App::RedisTop::Redis;

my $version = eval {
    require App::RedisTop;
    $App::RedisTop::VERSION;
};
if($@) { $version = '?' }

sub new {
    my $class = shift;

    my ($rows, $cols) = qx{stty -F /dev/tty size} =~ /^(\d+)\s+(\d+)/;

    my $self = bless {
        groups     => [],
        instances  => [],
        width      => 20,
        summary    => {},
        prev_stats => {},
        displayed  => 0,
        rows       => $rows,
        cols       => $cols,
        @_,
    }, $class;
    my $max_len = max (map { length($_) } @{$self->{instances}});
    $self->{width} = $max_len;
    $self;
}

sub separator { colored("|", "blue") }

sub build_title {
    return ();
}

sub build_header {
    my ($self) = @_;
    my $out_str = sprintf("%s ", ' ' x $self->{width});
    for my $group (@{$self->{groups}}) {
        $out_str .= $group->header;
    }
    return ("$out_str\n");
}

sub build_sub_header {
    my ($self) = @_;
    my $format = "%" . $self->{width} . "s%s";
    my $out_str = colored(sprintf($format, 'INSTANCE', $self->separator), "bold");
    for my $group (@{$self->{groups}}) {
        $out_str .= $group->sub_header;
    }
    return ("$out_str\n");
}

sub build_line {
    my ($self, $spt) = @_;
    my $out_str = colored(sprintf("%s ", $spt x $self->{width}), "blue");
    for my $group (@{$self->{groups}}) {
        $out_str .= $group->line($spt);
    }
    return ("$out_str\n");
}

sub build_body {
    my ($self, $instance, $stats, $prev_stats, $redis_config) = @_;
    my $format = "%" . $self->{width} . "s%s";
    my $out_str = sprintf($format, $instance, $self->separator);
    for my $group (@{$self->{groups}}) {
        $group->redis_config($redis_config);
        $out_str .= $group->body($stats, $prev_stats);

        # stash total count
        my @values = $group->stat_values($stats, $prev_stats);
        my $key    = $group->{group};
        my $total_values = $self->{summary}->{$key} || [];
        for (my $i = 0; $i < scalar @values; $i++){
            $total_values->[$i] ||= 0;
            $total_values->[$i] += $values[$i];
        }
        $self->{summary}->{$key} = $total_values;
    }
    return ("$out_str\n");
}

sub build_average {
    my ($self) = @_;
    my $instance_count = scalar @{$self->{instances}};

    my $format = "%" . $self->{width} . "s%s";
    my $out_str = colored(sprintf($format, 'AVERAGE', $self->separator), "bold");
    for my $group (@{$self->{groups}}) {
        my $key   = $group->{group};
        $out_str .= $group->average($self->{summary}->{$key}, $instance_count);
    }
    return ("$out_str\n");
}

sub build_total {
    my ($self) = @_;
    my $format = "%" . $self->{width} . "s%s";
    my $out_str = colored(sprintf($format, 'TOTAL', $self->separator), "bold");
    for my $group (@{$self->{groups}}) {
        my $key   = $group->{group};
        $out_str .= $group->total($self->{summary}->{$key});
    }
    return ("$out_str\n");
}

sub run {
    my ($self) = @_;

    # init total
    $self->{summary} = {};

    my @lines;
    if ($self->{displayed} == 0) {
        # build header
        push @lines, $self->build_title;
        push @lines, $self->build_header;
        push @lines, $self->build_sub_header;
        push @lines, $self->build_line('-');
    }

    # instances loop
    foreach my $instance (@{$self->{instances}}) {
        my ($host, $port) = split(/:/, $instance);

        my $redis   = App::RedisTop::Redis->new(host => $host, port => $port);
        my $config  = $redis->config();
        my $stats   = $redis->info();
        my $slowlog = $redis->slowlog();
        # add slowlog len into stats
        $stats->{slowlog_len} = $slowlog;

        push @lines, $self->build_body(
            $instance,
            $stats,
            $self->{prev_stats}->{$instance} || {},
            $config,
        );
        $self->{prev_stats}->{$instance} = $stats;
    }

    if ($self->{displayed} == 0) {
        # average
        push @lines, $self->build_average();
        # total
        push @lines, $self->build_total();
    }

    print join('', @lines);
    $self->{displayed} += scalar(@lines);
    if ($self->{displayed} >= $self->{rows}) {
        $self->{displayed} = 0;
    }
}

1;
