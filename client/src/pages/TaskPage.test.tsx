import { act, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { TaskPage } from './TaskPage'
import { api, type Comment, type Task } from '../api'
import { subscribeToTaskComments, type CommentEvent } from '../cable'

vi.mock('../api', async (importOriginal) => {
  const actual = await importOriginal<typeof import('../api')>()
  return {
    ...actual,
    api: { ...actual.api, task: vi.fn(), comments: vi.fn(), createComment: vi.fn(), deleteComment: vi.fn() },
  }
})
vi.mock('../cable', () => ({ subscribeToTaskComments: vi.fn() }))

const me = { id: 1, email: 'ada@example.com', name: 'Ada', created_at: '' }
const task: Task = {
  id: 7,
  title: 'Prepare demo',
  description: 'Show realtime comments',
  completed: false,
  due_on: null,
  comments_count: 1,
  created_at: '',
  updated_at: '',
  creator: { id: 2, name: 'Grace' },
}
const comment = (id: number, body: string, userId = 2): Comment => ({
  id,
  task_id: 7,
  body,
  created_at: '2026-10-19T00:00:00Z',
  updated_at: '2026-10-19T00:00:00Z',
  user: { id: userId, name: userId === 1 ? 'Ada' : 'Grace' },
})

let pushEvent: (event: CommentEvent) => void
const unsubscribe = vi.fn()

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/tasks/7']}>
      <Routes>
        <Route path="/tasks/:id" element={<TaskPage session={{ user: me, token: 'tok' }} />} />
      </Routes>
    </MemoryRouter>,
  )
}

beforeEach(() => {
  vi.mocked(api.task).mockResolvedValue({ task })
  vi.mocked(api.comments).mockResolvedValue({ comments: [comment(1, 'First!')], next_cursor: null, limit: 50 })
  vi.mocked(subscribeToTaskComments).mockImplementation((_taskId, _token, onEvent) => {
    pushEvent = onEvent
    return unsubscribe
  })
})

describe('TaskPage', () => {
  it('shows the task and its comments', async () => {
    renderPage()

    expect(await screen.findByRole('heading', { name: 'Prepare demo' })).toBeInTheDocument()
    expect(await screen.findByText('First!')).toBeInTheDocument()
    expect(subscribeToTaskComments).toHaveBeenCalledWith(7, 'tok', expect.any(Function))
  })

  it('adds a comment that arrives over the live feed', async () => {
    renderPage()
    await screen.findByText('First!')

    act(() => pushEvent({ type: 'comment.created', comment: comment(2, 'Live from Grace') }))

    expect(screen.getByText('Live from Grace')).toBeInTheDocument()
  })

  it('removes a comment deleted over the live feed', async () => {
    renderPage()
    await screen.findByText('First!')

    act(() => pushEvent({ type: 'comment.deleted', comment: { id: 1, task_id: 7 } }))

    expect(screen.queryByText('First!')).not.toBeInTheDocument()
  })

  it('posts a new comment', async () => {
    vi.mocked(api.createComment).mockResolvedValue({ comment: comment(3, 'On it', 1) })
    renderPage()
    await screen.findByText('First!')

    await userEvent.type(screen.getByLabelText('Add a comment'), 'On it')
    await userEvent.click(screen.getByRole('button', { name: 'Post' }))

    expect(api.createComment).toHaveBeenCalledWith('tok', 7, 'On it')
    expect(await screen.findByText('On it')).toBeInTheDocument()
    expect(screen.getByLabelText('Add a comment')).toHaveValue('')
  })

  it('only offers Delete on your own comments', async () => {
    vi.mocked(api.comments).mockResolvedValue({
      comments: [comment(1, 'Mine', 1), comment(2, 'Theirs', 2)],
      next_cursor: null,
      limit: 50,
    })
    renderPage()
    await screen.findByText('Mine')

    expect(screen.getAllByRole('button', { name: 'Delete comment' })).toHaveLength(1)
  })

  it('unsubscribes when leaving the page', async () => {
    const { unmount } = renderPage()
    await screen.findByText('First!')

    unmount()

    expect(unsubscribe).toHaveBeenCalled()
  })
})
