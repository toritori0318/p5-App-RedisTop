package App::RedisTop::Component;
use Term::ANSIColor qw/colored/;

sub new {
    my $class = shift;

    my %args = @_;
    my $self = bless {
        redis_config => $args{redis_config},
    }, $class;
}

sub redis_config {
    my ($self, $value) = @_;
    if($value) {
        $self->{redis_config} = $value;
    }
    return $self->{redis_config};
}

sub stat_values {
    my ($self, $stat, $prev_stat) = @_;
    my @results;
    for my $row (@{$self->{items}}) {
        my $stat_key = ref $row->{stat_key} eq 'CODE' ? $row->{stat_key}->($stat->{redis_version}) : $row->{stat_key};
        my $value;
        if ($row->{diff}) {
            my $prev_uptime = $prev_stat->{uptime_in_seconds} || 0;
            my $prev_value  = $prev_stat->{$stat_key} || 0;
            eval {
                $value
                    = ( $stat->{$stat_key} - $prev_value )
                    / ( $stat->{uptime_in_seconds} - $prev_uptime);
            };
            if ($@) {
                $value = $stat->{$stat_key};
            }
        } elsif($row->{denominator_key}) {
            if($self->redis_config && $self->redis_config->{$row->{denominator_key}}) {
                $value = sprintf("%.2f", ($stat->{$stat_key} / $self->redis_config->{$row->{denominator_key}}) * 100);
            } else {
                $value = "-1";
            }
        } elsif($row->{data}) {
            $value = $row->{data}->();
        } else {
            $value = $stat->{$stat_key};
        }
        push @results, $value;
    }
    return @results;
}

sub unit {
    my ($self, $value) = @_;
    $value ||= 0;

    my $round = '';
    my @units = qw/K M G T P/;
    unshift @units, ' ';
    for my $unit (@units) {
        if($value / 1000 < 1) {
            $round = 2 if index($value, '.') > 0; # float
            return sprintf("%.${round}f%s", $value, $unit);
        }
        $value = $value / 1000;
        $round = 2;
    }
}

sub separator { colored("|", "blue") }

sub header {
    my ($self) = @_;
    my $title = $self->{group};
    my $diff  = $self->component_width - length($title);
    my $left  = $diff / 2;
    my $right = $diff - $left;

    my $line     = '-' x $left . $title . '-' x $right;
    my $line_len = length($line);
    if($line_len > $self->component_width-1) {
        $line = substr($line, 0, length($line)-1);
    } elsif($line_len < $self->component_width-1) {
        $line .= '-';
    }
    return colored("${line} ", "blue");
}

sub sub_header {
    my ($self) = @_;
    my $format = "%" . $self->{width} . "s";
    my $line   = join(' ', map { sprintf($format, $_->{name}) } @{$self->{items}});
    return colored("${line}", "cyan") . $self->separator;
}

sub line {
    my ($self, $spt) = @_;
    my $item_len = scalar @{$self->{items}};
    my $line     = join(' ', map { $spt x $self->{width} } 1..$item_len);
    return colored("${line} ", "blue");
}

sub component_width {
    my ($self) = @_;
    my $line = $self->line('-');
    return length($self->colorstrip($self->line('-')));
}

sub colorstrip {
    my ($self, @string) = @_;
    for my $string (@string) {
        $string =~ s{ \e\[ [\d;]* m }{}xmsg;
    }
    return wantarray ? @string : join q{}, @string;
}

sub body {
    my ($self, $stat, $prev_stat) = @_;
    my @cols;
    for my $value ($self->stat_values($stat, $prev_stat)) {
        my $stat   = ($self->{unit}) ? $self->unit($value) : $value;
        my $format = ($self->{round}) ? "%" . $self->{width} . ".1f" : "%" . $self->{width} . "s" ;
        push @cols, sprintf($format, $stat);
    }
    my $line = join(' ', @cols);
    return $line . $self->separator;
}

sub average {
    my ($self, $values, $instance_count) = @_;
    $values ||= [ map { '' } @{$self->{items}} ];

    my @cols;
    for my $value (@$values) {
        my $avg_value = 0;
        $avg_value = $value / $instance_count if $value && $instance_count;

        my $stat   = ($self->{unit}) ? $self->unit($avg_value) : $avg_value;
        my $format = ($self->{round}) ? "%" . $self->{width} . ".1f" : "%" . $self->{width} . "s" ;
        push @cols, sprintf($format, $stat);
    }
    my $line = join(' ', @cols);
    return $line . $self->separator;
}

sub total {
    my ($self, $values) = @_;

    my @cols;
    for my $value (@$values) {
        my $stat = '';
        if($self->{total}){
            $stat = ($self->{unit}) ? $self->unit($value) : $value;
        }
        my $format = "%" . $self->{width} . "s";
        push @cols, sprintf($format, $stat);
    }
    my $line = join(' ', @cols);
    return $line . $self->separator;
}

1;
