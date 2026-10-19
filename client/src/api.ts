// Thin client for the Rails JSON API. Every call takes the bearer token explicitly
// so components stay easy to test.

export const API_URL: string = import.meta.env.VITE_API_URL ?? 'http://localhost:3000'

export type User = { id: number; email: string; name: string; created_at: string }
export type Person = { id: number; name: string }

export type Task = {
  id: number
  title: string
  description: string | null
  completed: boolean
  due_on: string | null
  comments_count: number
  created_at: string
  updated_at: string
  creator: Person
}

export type Comment = {
  id: number
  task_id: number
  body: string
  created_at: string
  updated_at: string
  user: Person
}

export type Session = { user: User; token: string }
export type TaskInput = Partial<Pick<Task, 'title' | 'description' | 'completed' | 'due_on'>>
export type CommentPage = { comments: Comment[]; next_cursor: number | null; limit: number }

export class ApiError extends Error {
  readonly status: number
  readonly errors: Record<string, string[]>

  constructor(status: number, message: string, errors: Record<string, string[]> = {}) {
    super(message)
    this.status = status
    this.errors = errors
  }
}

async function request<T>(path: string, options: { method?: string; token?: string; body?: unknown } = {}): Promise<T> {
  const headers: Record<string, string> = { Accept: 'application/json' }
  if (options.body !== undefined) headers['Content-Type'] = 'application/json'
  if (options.token) headers.Authorization = `Bearer ${options.token}`

  const response = await fetch(`${API_URL}${path}`, {
    method: options.method ?? 'GET',
    headers,
    body: options.body === undefined ? undefined : JSON.stringify(options.body),
  })

  if (response.status === 204) return null as T

  const data = await response.json().catch(() => ({}))
  if (!response.ok) {
    const errors: Record<string, string[]> = data.errors ?? {}
    const fieldMessages = Object.entries(errors).flatMap(([field, messages]) => messages.map((m) => `${field} ${m}`))
    throw new ApiError(response.status, fieldMessages.join(', ') || data.error || response.statusText, errors)
  }
  return data as T
}

export const api = {
  signUp: (user: { name: string; email: string; password: string }) =>
    request<Session>('/api/v1/users', { method: 'POST', body: { user } }),
  login: (email: string, password: string) =>
    request<Session>('/api/v1/sessions', { method: 'POST', body: { email, password } }),

  tasks: (token: string) => request<{ tasks: Task[] }>('/api/v1/tasks', { token }),
  task: (token: string, id: number) => request<{ task: Task }>(`/api/v1/tasks/${id}`, { token }),
  createTask: (token: string, task: TaskInput) =>
    request<{ task: Task }>('/api/v1/tasks', { method: 'POST', token, body: { task } }),
  updateTask: (token: string, id: number, task: TaskInput) =>
    request<{ task: Task }>(`/api/v1/tasks/${id}`, { method: 'PATCH', token, body: { task } }),
  deleteTask: (token: string, id: number) => request<null>(`/api/v1/tasks/${id}`, { method: 'DELETE', token }),

  comments: (token: string, taskId: number, after?: number | null) =>
    request<CommentPage>(`/api/v1/tasks/${taskId}/comments${after ? `?after=${after}` : ''}`, { token }),
  createComment: (token: string, taskId: number, body: string) =>
    request<{ comment: Comment }>(`/api/v1/tasks/${taskId}/comments`, { method: 'POST', token, body: { comment: { body } } }),
  deleteComment: (token: string, id: number) => request<null>(`/api/v1/comments/${id}`, { method: 'DELETE', token }),
}
