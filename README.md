PlugSessionRedis for Ruby rack (redis-store)
================
[![hex.pm version](https://img.shields.io/hexpm/v/plug_session_redis.svg)](https://hex.pm/packages/plug_session_redis)

The Redis Plug.Session adapter for the Phoenix framework with Rails redis-store session.
Poolboy + Redis.

## Usage
```elixir
# mix.exs
def application do
  [applications: [..., :plug_session_redis]]
end

defp deps do
  [{:plug_session_redis, git: "https://github.com/rinosamakanata/plug_session_redis.git", branch: "master" }]
end
```

## config.exs
```elixir
config :plug_session_redis, :config,
  name: :redis_sessions,    # Can be anything you want, should be the same as `:table` config below
  pool: [size: 2, max_overflow: 5],
  redis: [host: '127.0.0.1', port: 6379]
```

## endpoint.ex  
```elixir
plug Plug.Session,
  store: PlugSessionRedis.Store,
  key: "_session_id",           #
  table: :redis_sessions,       # Can be anything you want, should be same as `:name` config above
```
