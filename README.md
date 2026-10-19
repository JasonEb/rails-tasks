# Realtime Tasks

A Rails 8 JSON API for a shared task list with realtime comments, backed by PostgreSQL and Redis. A minimal React client will be added under `client/`.

Built test-first: model specs, then request specs, then the code that makes them pass. See [docs/architecture.md](docs/architecture.md) for the system design.

## Requirements

- Ruby 3.3.6
- Docker (for Postgres 16 and Redis 7), or local installs of both

## Setup

```sh
docker compose up -d          # Postgres on 5432, Redis on 6379
bundle install
bin/rails db:prepare
bundle exec rspec
bin/rails server
```

Database settings come from `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USERNAME` and `DATABASE_PASSWORD` (defaults: `localhost`, `5432`, `postgres`, `postgres`). Redis comes from `REDIS_URL` (default `redis://localhost:6379/1`).

## Realtime comments

Comments are pushed to subscribers over Action Cable, which uses Redis pub/sub so every Rails process sees every message.

1. Connect to `ws://localhost:3000/cable?token=<auth_token>`. Browsers can't set headers on a WebSocket, so the token goes in the query string.
2. Subscribe with the identifier `{"channel": "TaskCommentsChannel", "task_id": 1}`.
3. You'll receive `{"type": "comment.created", "comment": {...}}` and `{"type": "comment.deleted", "comment": {"id": ..., "task_id": ...}}`.

Broadcasts happen after the database transaction commits, so a rolled-back comment is never pushed. WebSocket connections are only accepted from `CLIENT_ORIGIN` (default `http://localhost:5173`).

## Roadmap

1. Scaffold and test setup
2. JSON API for Users, Tasks and Comments
3. Realtime comments over Action Cable with the Redis adapter
4. Minimal React client
