import { createConsumer, type Consumer } from '@rails/actioncable'
import { API_URL, type Comment } from './api'

export type CommentEvent =
  | { type: 'comment.created'; comment: Comment }
  | { type: 'comment.deleted'; comment: { id: number; task_id: number } }

const CABLE_URL = API_URL.replace(/^http/, 'ws') + '/cable'

let consumer: Consumer | null = null
let consumerToken: string | null = null

// One WebSocket per signed-in user. Browsers can't set headers on a
// WebSocket, so the token rides in the query string.
function consumerFor(token: string): Consumer {
  if (!consumer || consumerToken !== token) {
    consumer?.disconnect()
    consumer = createConsumer(`${CABLE_URL}?token=${encodeURIComponent(token)}`)
    consumerToken = token
  }
  return consumer
}

export function subscribeToTaskComments(taskId: number, token: string, onEvent: (event: CommentEvent) => void) {
  const subscription = consumerFor(token).subscriptions.create(
    { channel: 'TaskCommentsChannel', task_id: taskId },
    { received: (event: CommentEvent) => onEvent(event) },
  )
  return () => {
    subscription.unsubscribe()
  }
}

export function disconnectCable() {
  consumer?.disconnect()
  consumer = null
  consumerToken = null
}
