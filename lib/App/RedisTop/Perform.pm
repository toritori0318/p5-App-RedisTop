package App::RedisTop::Perform;
use Term::ANSIColor qw/colored/;
use List::Util qw/max/;

my $version = eval {
    require App::RedisTop;
    $App::RedisTop::VERSION;
};
if($@) { $version = '?' }

sub new {
    my $class = shift;

    my $self = bless {
        groups     => [],
        instances  => [],
        width      => 20,
        summary    => {},
        prev_stats => {},
        @_,
    }, $class;
    my $max_len = max (map { length($_) } @{$self->{instances}});
    $self->{width} = $max_len;
    $self;
}

sub separator { colored("|", "blue") }

sub redis_info {
    my ($self, $host, $port, $pass) = @_;

    my $server = "$host:$port";
    my $s = IO::Socket::INET->new(
        PeerAddr => $server,
        Proto    => 'tcp',
    ) or die "[$server] socket connect error: $!";

    # auth
    if ($pass) {
        $s->print("AUTH $pass \r\n");
        <$s> || die "[$server] socket auth error: $!";
    }

    # info
    $s->print("INFO\r\n");
    my $count = <$s> || die "[$server] socket read error: $!";
    $s->read(my $buf, substr($count, 1) ) or die "[$server] socket read error: $!";

    my $stats = {};
    for my $row (split(/\r\n/, $buf)) {
        next if $row =~ /^#/;
        next if $row =~ /^$/;
        my ($key, $val) = split(/:/, $row);
        $stats->{$key} = $val;
    }

    close ($s);

    return $stats;
}

sub build_title {
    my @lines;
    push @lines, "\033[2J\n";
    push @lines, colored(sprintf("redis-top v%s\n\n", $version), "bold");
    return @lines;
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
    my ($self, $instance, $stats, $prev_stats) = @_;
    my $format = "%" . $self->{width} . "s%s";
    my $out_str = sprintf($format, $instance, $self->separator);
    for my $group (@{$self->{groups}}) {
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
    # build header
    push @lines, $self->build_title;
    push @lines, $self->build_header;
    push @lines, $self->build_sub_header;
    push @lines, $self->build_line('-');

    # instances loop
    foreach my $instance (@{$self->{instances}}) {
        my ($server, $port) = split(/:/, $instance);
        my $stats = $self->redis_info($server, $port);
        push @lines, $self->build_body(
            $instance,
            $stats,
            $self->{prev_stats}->{$instance} || {},
        );
        $self->{prev_stats}->{$instance} = $stats;
    }

    # average
    push @lines, $self->build_line(' ');
    push @lines, $self->build_average();
    # total
    push @lines, $self->build_line(' ');
    push @lines, $self->build_total();

    print join('', @lines);
}

1;
