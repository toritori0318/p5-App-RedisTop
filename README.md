# App::RedisTop
redis-top - Redis resource statistics tool.

## Installation

    cpanm App::RedisTop

or

    curl -L -o redis-top https://raw.githubusercontent.com/toritori0318/p5-App-RedisTop/master/redis-top-pack
    perl redis-top
    # setup redis-stat
    ln -s redis-top redis-stat

## ScreenShot

<img src="redis_top_screen.png" width="450px" />

## Usage

    Usage:
        redis-top [options]
        redis-stat [options]

      Example:
        redis-top -i 127.0.0.1:6379,127.0.0.1:6380,127.0.0.1:6381,127.0.0.1:6382
        redis-top --sleep 1 --nocolor --cpu --memory --db
        redis-top --cpu --memory --conn --save --command --db  # default
        redis-top -cMnsCdmolt # full

    Options:
      Group Options:
        -c,--cpu
            enable cpu stats

        -M,--memory
            enable memory stats

        -m,--memoryper
            enable used_memory/maxmemory stats

        -n,--conn
            enable connection stats

        -o,--connper
            enable connected_clients/maxclients stats

        -s,--save
            enable save stats

        -C,--command
            enable command stats

        -l,--slowlog
            enable slowlog stats

        -d,--db
            enable db stats (default:db0 stats)

        -t,--time
            enable time output

      Global Options:
        --sleep
            sleep time (default:3)

        --nocolor
            disable colors

        -h --help
            show help


## License

This library is free software; you can redistribute it and/or modify

it under the same terms as Perl itself.

