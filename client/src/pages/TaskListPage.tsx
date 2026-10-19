import { useEffect, useState, type FormEvent } from 'react'
import { Link } from 'react-router'
import { api, type Session, type Task } from '../api'

export function TaskListPage({ session }: { session: Session }) {
  const [tasks, setTasks] = useState<Task[] | null>(null)
  const [title, setTitle] = useState('')
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    api.tasks(session.token).then(({ tasks }) => setTasks(tasks), (e: Error) => setError(e.message))
  }, [session.token])

  async function handleCreate(event: FormEvent) {
    event.preventDefault()
    setError(null)
    try {
      const { task } = await api.createTask(session.token, { title })
      setTasks((current) => [task, ...(current ?? [])])
      setTitle('')
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not create the task')
    }
  }

  async function toggle(task: Task) {
    const { task: updated } = await api.updateTask(session.token, task.id, { completed: !task.completed })
    setTasks((current) => current?.map((t) => (t.id === updated.id ? updated : t)) ?? null)
  }

  return (
    <main className="card">
      <h1>Tasks</h1>
      <form onSubmit={handleCreate} className="row">
        <label className="grow">
          <span className="visually-hidden">New task</span>
          <input placeholder="What needs doing?" value={title} onChange={(e) => setTitle(e.target.value)} required />
        </label>
        <button type="submit">Add</button>
      </form>
      {error && <p role="alert" className="error">{error}</p>}
      {tasks === null ? (
        <p>Loading…</p>
      ) : tasks.length === 0 ? (
        <p className="muted">No tasks yet.</p>
      ) : (
        <ul className="list">
          {tasks.map((task) => (
            <li key={task.id} className="row">
              {task.creator.id === session.user.id ? (
                <input
                  type="checkbox"
                  checked={task.completed}
                  onChange={() => toggle(task)}
                  aria-label={`Mark ${task.title} ${task.completed ? 'not done' : 'done'}`}
                />
              ) : (
                <span aria-hidden="true">{task.completed ? '✓' : '·'}</span>
              )}
              <Link to={`/tasks/${task.id}`} className={`grow ${task.completed ? 'done' : ''}`}>
                {task.title}
              </Link>
              <span className="muted">
                {task.creator.name} · {task.comments_count} {task.comments_count === 1 ? 'comment' : 'comments'}
              </span>
            </li>
          ))}
        </ul>
      )}
    </main>
  )
}
