# Architecture

PostgreSQL holds every record. Redis only carries live messages between Rails processes, so losing Redis drops live updates but never loses data.

Tasks are shared: every signed-in user can see any task and comment on it. Only a task's creator can edit or delete it, and only a comment's author can delete that comment.

## System overview

```mermaid
flowchart LR
  subgraph Client
    R[React app<br/>Vite]
  end
  subgraph Rails["Rails 8 API"]
    C[Controllers<br/>/api/v1]
    M[Models<br/>User, Task, Comment]
    AC[Action Cable<br/>TaskCommentsChannel]
  end
  PG[(PostgreSQL)]
  RD[(Redis<br/>pub/sub)]

  R -- "HTTPS JSON + bearer token" --> C
  R <-- "WebSocket" --> AC
  C --> M
  M -- "read / write" --> PG
  M -- "after_create_commit broadcast" --> RD
  RD -- "fan-out to subscribers" --> AC
```

## Data model

```mermaid
erDiagram
  USER ||--o{ TASK : creates
  USER ||--o{ COMMENT : writes
  TASK ||--o{ COMMENT : has

  USER {
    bigint id PK
    string email "unique, not null"
    string name
    string password_digest
    string auth_token "unique"
    datetime created_at
  }
  TASK {
    bigint id PK
    bigint creator_id FK "references users"
    string title "not null"
    text description
    boolean completed "default false"
    date due_on
    integer comments_count "counter cache"
    datetime created_at
  }
  COMMENT {
    bigint id PK
    bigint task_id FK
    bigint user_id FK
    text body "not null"
    datetime created_at
  }
```

## Phase 1 endpoints

| Method | Path | Purpose | Who |
| --- | --- | --- | --- |
| POST | `/api/v1/users` | Sign up | Anyone |
| POST | `/api/v1/sessions` | Log in, returns a token | Anyone |
| GET | `/api/v1/me` | Current user | Signed in |
| GET, POST | `/api/v1/tasks` | List all tasks, or create one | Signed in |
| GET | `/api/v1/tasks/:id` | Read one task | Signed in |
| PATCH, DELETE | `/api/v1/tasks/:id` | Update or delete a task | Task creator |
| GET, POST | `/api/v1/tasks/:task_id/comments` | List or add comments on a task | Signed in |
| DELETE | `/api/v1/comments/:id` | Delete a comment | Comment author |

## Posting a comment in real time (phase 2)

```mermaid
sequenceDiagram
  participant A as Author (React)
  participant API as Rails API
  participant DB as PostgreSQL
  participant RD as Redis
  participant AC as Action Cable
  participant V as Other viewers (React)

  V->>AC: subscribe(TaskCommentsChannel, task_id)
  A->>API: POST /api/v1/tasks/:id/comments
  API->>DB: INSERT comment (transaction)
  DB-->>API: committed
  API-->>A: 201 Created + comment JSON
  API->>RD: after_create_commit: publish task:ID:comments
  RD-->>AC: message
  AC-->>V: comment JSON over WebSocket
```

Broadcasting after commit, not after save, means a viewer never sees a comment that was rolled back.
