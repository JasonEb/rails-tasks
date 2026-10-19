# Live comment feed for one task. Any signed-in user can subscribe,
# matching the REST rule that every user can read every task.
#
# Client: consumer.subscriptions.create({ channel: "TaskCommentsChannel", task_id: 1 })
# Messages: { type: "comment.created", comment: {...} }
#           { type: "comment.deleted", comment: { id:, task_id: } }
class TaskCommentsChannel < ApplicationCable::Channel
  def self.stream_name(task)
    "task:#{task.id}:comments"
  end

  def subscribed
    task = Task.find_by(id: params[:task_id])
    return reject unless task

    stream_from self.class.stream_name(task)
  end
end
