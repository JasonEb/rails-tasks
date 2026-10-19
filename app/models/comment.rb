class Comment < ApplicationRecord
  belongs_to :task, counter_cache: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 5_000 }

  # After commit, not after save: viewers never see a comment that rolls back.
  after_create_commit :broadcast_created
  after_destroy_commit :broadcast_deleted

  scope :oldest_first, -> { order(:id) }
  scope :after_cursor, ->(cursor) { cursor.present? ? where(id: (cursor.to_i + 1)..) : all }

  private

  def broadcast_created
    broadcast("comment.created", CommentResource.new(self).to_h)
  end

  def broadcast_deleted
    broadcast("comment.deleted", { id: id, task_id: task_id })
  end

  def broadcast(type, comment)
    ActionCable.server.broadcast(TaskCommentsChannel.stream_name(task), { type: type, comment: comment })
  end
end
