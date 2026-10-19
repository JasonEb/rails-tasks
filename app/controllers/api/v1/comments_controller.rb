module Api
  module V1
    # Any signed-in user can read and add comments on any task.
    # Only a comment's author can delete it.
    class CommentsController < BaseController
      DEFAULT_LIMIT = 50
      MAX_LIMIT = 100

      before_action :set_task, only: %i[index create]

      # Cursor pagination: pass `after=<id>` from the previous page's `next_cursor`.
      def index
        limit = params.fetch(:limit, DEFAULT_LIMIT).to_i.clamp(1, MAX_LIMIT)
        page = @task.comments.includes(:user).oldest_first.after_cursor(params[:after]).limit(limit + 1).to_a
        comments = page.first(limit)
        next_cursor = page.size > limit ? comments.last.id : nil

        render json: { comments: CommentResource.new(comments).to_h, next_cursor: next_cursor, limit: limit }
      end

      def create
        comment = @task.comments.build(comment_params.merge(user: current_user))

        if comment.save
          render json: { comment: CommentResource.new(comment).to_h }, status: :created
        else
          render_errors(comment)
        end
      end

      def destroy
        comment = Comment.find(params[:id])
        authorize_owner!(comment.user_id)

        comment.destroy!
        head :no_content
      end

      private

      def set_task
        @task = Task.find(params[:task_id])
      end

      def comment_params
        params.expect(comment: [ :body ])
      end
    end
  end
end
