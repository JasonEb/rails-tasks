import type { Comment } from './api'
import type { CommentEvent } from './cable'

// Folds one live event into the current list. The author gets their own
// comment twice (from the POST response and the broadcast), so created
// events are de-duplicated by id.
export function applyCommentEvent(comments: Comment[], event: CommentEvent): Comment[] {
  switch (event.type) {
    case 'comment.created':
      if (comments.some((c) => c.id === event.comment.id)) return comments
      return [...comments, event.comment].sort((a, b) => a.id - b.id)
    case 'comment.deleted':
      return comments.filter((c) => c.id !== event.comment.id)
  }
}
