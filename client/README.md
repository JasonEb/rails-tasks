# Rails Tasks client

A minimal React (Vite + TypeScript) client for the Rails API: log in or sign up, see the shared task list, and open a task to read and post comments that update live over Action Cable.

```sh
npm install
npm run dev        # http://localhost:5173, expects the API on http://localhost:3000
npm test           # Vitest + React Testing Library
```

Set `VITE_API_URL` to point at a different API. The API only accepts browser and WebSocket requests from `CLIENT_ORIGIN` (default `http://localhost:5173`).

| File | Purpose |
| --- | --- |
| `src/api.ts` | Typed fetch wrapper for every endpoint, bearer token per call |
| `src/cable.ts` | One Action Cable consumer per user; `subscribeToTaskComments` returns an unsubscribe function |
| `src/comments.ts` | Pure reducer that folds live events into the comment list, de-duplicating by id |
| `src/pages/` | Login, task list and task page |
