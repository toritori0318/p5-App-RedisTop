use strict;

use Test::More;
use IO::String;
use App::RedisTop::Component::CPU;
use App::RedisTop::Component::Memory;
use App::RedisTop::Component::Connection;
use App::RedisTop::Component::Save;
use App::RedisTop::Component::Command;
use App::RedisTop::Component::DB;

my $test_stats = {
   'bgsave_in_progress'         => 0,
   'blocked_clients'            => 0,
   'changes_since_last_save'    => 3,
   'connected_clients'          => 4,
   'connected_slaves'           => 0,
   'db0'                        => 'keys=55,expires=21',
   'evicted_keys'               => 0,
   'expired_keys'               => 0,
   'keyspace_hits'              => 4,
   'keyspace_misses'            => 7,
   'last_save_time'             => 1363622232,
   'mem_fragmentation_ratio'    => 1.33,
   'pubsub_channels'            => 0,
   'pubsub_patterns'            => 0,
   'redis_version'              => '2.4.5',
   'role'                       => 'master',
   'total_commands_processed'   => 11,
   'total_connections_received' => 6,
   'uptime_in_days'             => 0,
   'uptime_in_seconds'          => 4508,
   'used_cpu_sys'               => 4.35,
   'used_cpu_user'              => 3.41,
   'used_memory'                => 952160,
   'used_memory_peak'           => 953568,
   'used_memory_rss'            => 1341088,
};

my $test_prev_stats = {
   'bgsave_in_progress'         => 0,
   'blocked_clients'            => 0,
   'changes_since_last_save'    => 0,
   'connected_clients'          => 1,
   'connected_slaves'           => 0,
   'db0'                        => 'keys=5,expires=0',
   'evicted_keys'               => 0,
   'expired_keys'               => 0,
   'keyspace_hits'              => 1,
   'keyspace_misses'            => 2,
   'last_save_time'             => 1363622232,
   'mem_fragmentation_ratio'    => 1.33,
   'pubsub_channels'            => 0,
   'pubsub_patterns'            => 0,
   'redis_version'              => '2.4.5',
   'role'                       => 'master',
   'total_commands_processed'   => 3,
   'total_connections_received' => 1,
   'uptime_in_days'             => 0,
   'uptime_in_seconds'          => 4507,
   'used_cpu_sys'               => 1.35,
   'used_cpu_user'              => 1.41,
   'used_memory'                => 932160,
   'used_memory_peak'           => 923568,
   'used_memory_rss'            => 1241088,
};

my %groups = (
    cpu => {
        class => App::RedisTop::Component::CPU->new(),
        test  => {
            header     => "\e[34m-----cpu----- \e[0m",
            sub_header => "\e[36m   sys    usr\e[0m\e[34m|\e[0m",
            body       => "   3.0    2.0\e[34m|\e[0m",
        },
    },
    memory => {
        class => App::RedisTop::Component::Memory->new(),
        test  => {
            header     => "\e[34m----------mem---------- \e[0m",
            sub_header => "\e[36m    use     rss    frag\e[0m\e[34m|\e[0m",
            body       => "952.16K   1.34M   1.33 \e[34m|\e[0m",
        },
    },
    conn => {
        class => App::RedisTop::Component::Connection->new(),
        test  => {
            header     => "\e[34m--------conn------- \e[0m",
            sub_header => "\e[36m  total/s   clients\e[0m\e[34m|\e[0m",
            body       => "       5         4 \e[34m|\e[0m",
        },
    },
    save => {
        class => App::RedisTop::Component::Save->new(),
        test  => {
            header     => "\e[34m--save- \e[0m",
            sub_header => "\e[36mchanges\e[0m\e[34m|\e[0m",
            body       => "     3 \e[34m|\e[0m",
        },
    },
    command => {
        class => App::RedisTop::Component::Command->new(),
        test  => {
            header     => "\e[34m----------command--------- \e[0m",
            sub_header => "\e[36m total/s   hits/s misses/s\e[0m\e[34m|\e[0m",
            body       => "      8        3        5 \e[34m|\e[0m",
        },
    },
    db => {
        class => App::RedisTop::Component::DB->new(dbid => 0),
        test  => {
            header     => "\e[34m------db0------ \e[0m",
            sub_header => "\e[36m   keys expires\e[0m\e[34m|\e[0m",
            body       => "    55      21 \e[34m|\e[0m",
        },
    },
);
# test
for my $key (keys %groups) {
    my $header = $groups{$key}->{class}->header;
    is($header, $groups{$key}->{test}->{header}, "[$key] header ok");
    my $sub_header = $groups{$key}->{class}->sub_header;
    is($sub_header, $groups{$key}->{test}->{sub_header}, "[$key] sub header ok");
    my $body = $groups{$key}->{class}->body(
        $test_stats,
        $test_prev_stats,
    );
    is($body, $groups{$key}->{test}->{body}, "[$key] body ok");
}

done_testing;
