import { describe, expect, it } from 'vitest'
import { applyCommentEvent } from './comments'
import type { Comment } from './api'

const comment = (id: number, body = `Comment ${id}`): Comment => ({
  id,
  task_id: 1,
  body,
  created_at: '2026-10-19T00:00:00Z',
  updated_at: '2026-10-19T00:00:00Z',
  user: { id: 1, name: 'Ada' },
})

describe('applyCommentEvent', () => {
  it('appends a created comment', () => {
    const result = applyCommentEvent([comment(1)], { type: 'comment.created', comment: comment(2) })

    expect(result.map((c) => c.id)).toEqual([1, 2])
  })

  it('ignores a created comment it already has, so the author does not see it twice', () => {
    const list = [comment(1), comment(2)]

    expect(applyCommentEvent(list, { type: 'comment.created', comment: comment(2) })).toBe(list)
  })

  it('removes a deleted comment', () => {
    const result = applyCommentEvent([comment(1), comment(2)], {
      type: 'comment.deleted',
      comment: { id: 1, task_id: 1 },
    })

    expect(result.map((c) => c.id)).toEqual([2])
  })

  it('keeps comments in id order when one arrives out of order', () => {
    const result = applyCommentEvent([comment(1), comment(3)], { type: 'comment.created', comment: comment(2) })

    expect(result.map((c) => c.id)).toEqual([1, 2, 3])
  })
})
