import { useEffect, useState, type FormEvent } from 'react'
import { Link, useParams } from 'react-router'
import { api, type Comment, type Session, type Task } from '../api'
import { subscribeToTaskComments } from '../cable'
import { applyCommentEvent } from '../comments'

export function TaskPage({ session }: { session: Session }) {
  const taskId = Number(useParams().id)
  const [task, setTask] = useState<Task | null>(null)
  const [comments, setComments] = useState<Comment[]>([])
  const [nextCursor, setNextCursor] = useState<number | null>(null)
  const [body, setBody] = useState('')
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    api.task(session.token, taskId).then(({ task }) => setTask(task), (e: Error) => setError(e.message))
    api.comments(session.token, taskId).then((page) => {
      // Merge rather than replace, in case a live comment arrived before the first page.
      setComments((live) => page.comments.reduce((list, c) => applyCommentEvent(list, { type: 'comment.created', comment: c }), live))
      setNextCursor(page.next_cursor)
    })

    return subscribeToTaskComments(taskId, session.token, (event) => {
      setComments((current) => applyCommentEvent(current, event))
    })
  }, [taskId, session.token])

  async function loadMore() {
    const page = await api.comments(session.token, taskId, nextCursor)
    setComments((current) => page.comments.reduce((list, c) => applyCommentEvent(list, { type: 'comment.created', comment: c }), current))
    setNextCursor(page.next_cursor)
  }

  async function handlePost(event: FormEvent) {
    event.preventDefault()
    setError(null)
    try {
      const { comment } = await api.createComment(session.token, taskId, body)
      setComments((current) => applyCommentEvent(current, { type: 'comment.created', comment }))
      setBody('')
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not post the comment')
    }
  }

  async function handleDelete(comment: Comment) {
    await api.deleteComment(session.token, comment.id)
    setComments((current) => applyCommentEvent(current, { type: 'comment.deleted', comment }))
  }

  return (
    <main className="card">
      <Link to="/">← All tasks</Link>
      {task && (
        <header>
          <h1 className={task.completed ? 'done' : ''}>{task.title}</h1>
          <p className="muted">
            Created by {task.creator.name}
            {task.due_on && ` · due ${task.due_on}`}
          </p>
          {task.description && <p>{task.description}</p>}
        </header>
      )}

      <section aria-label="Comments">
        <h2>Comments</h2>
        <ul className="list">
          {comments.map((comment) => (
            <li key={comment.id}>
              <strong>{comment.user.name}</strong> <span className="muted">{new Date(comment.created_at).toLocaleString()}</span>
              <p>{comment.body}</p>
              {comment.user.id === session.user.id && (
                <button type="button" className="link" aria-label="Delete comment" onClick={() => handleDelete(comment)}>
                  Delete
                </button>
              )}
            </li>
          ))}
        </ul>
        {nextCursor && (
          <button type="button" className="link" onClick={loadMore}>
            Load more
          </button>
        )}
        <form onSubmit={handlePost} className="stack">
          <label>
            Add a comment
            <textarea value={body} onChange={(e) => setBody(e.target.value)} rows={3} required />
          </label>
          {error && <p role="alert" className="error">{error}</p>}
          <button type="submit">Post</button>
        </form>
      </section>
    </main>
  )
}
