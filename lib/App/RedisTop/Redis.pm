package App::RedisTop::Redis;

use strict;
use warnings;
use IO::Socket::INET;

sub new {
    my $class = shift;
    my (%args) = @_;

    my $host = $args{host} || '127.0.0.1';
    my $port = $args{port} || '6379';
    my $pass = $args{pass};

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

    my $self = bless {
        socket  => $s,
    }, $class;
    $self;
}

sub info {
    my ($self) = @_;

    my $buf = $self->command('INFO');

    my $stats = {};
    for my $row (split(/\r\n/, $buf)) {
        next if $row =~ /^#/;
        next if $row =~ /^$/;
        my ($key, $val) = split(/:/, $row);
        $stats->{$key} = $val;
    }

    return $stats;
}

sub config {
    my ($self) = @_;
    return $self->command("CONFIG", "GET", "*");
}

sub slowlog {
    my ($self) = @_;
    return $self->command("SLOWLOG", "LEN");
}

sub command {
    my ($self, @command) = @_;

    my $s = $self->{socket};
    my $req = $self->request(@command);

    $s->send($req);

    my $ret = $s->recv( my $buffer, 131072 );
    my @lines = split(/\r\n/, $buffer);
    my $header = $self->row_parser($lines[0]);
    return $buffer if $header->{type} eq 'itemlen';
    return $header->{value} if $header->{type} eq 'number';

    my %stats = ();
    my $key;

    for my $line (@lines) {
        my $row = $self->row_parser($line);
        if($row->{type} eq 'line') {
            unless($key) {
                $key = $row->{value};
            } else {
                $stats{$key} = $row->{value};
                $key = undef;
            }
        }
    }

    return \%stats;
}

sub row_parser {
    my ($self, $row) = @_;

    if($row =~ /^(\*|\$|\:)+(\w+)/) {
        if($1 eq '*') { # header
            return {
                type  => 'rowlen',
                value => $2,
            };
        } elsif($1 eq '$') { # next length
            return {
                type  => 'itemlen',
                value => $2,
            };
        } elsif($1 eq ':') { # number
            return {
                type  => 'number',
                value => $2,
            };
        }
    }

    $row =~ s/\r\n//;
    return {
        type  => 'line',
        value => $row,
    }
}

sub request {
    my ($self, @args) = @_;

    my $nl = "\015\012";
    my $req = sprintf('*%d%s', scalar(@args), $nl);
    $req .= sprintf('$%d%s%s%s', length($_), $nl, $_, $nl) for @args;
    return $req;
}

1;
