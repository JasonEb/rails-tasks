module Api
  module V1
    # Tasks are shared: any signed-in user can list, read and create them.
    # Only the creator can update or delete a task.
    class TasksController < BaseController
      before_action :set_task, only: %i[show update destroy]
      before_action -> { authorize_owner!(@task.creator_id) }, only: %i[update destroy]

      def index
        tasks = Task.includes(:creator).newest_first
        render json: { tasks: TaskResource.new(tasks).to_h }
      end

      def show
        render json: { task: TaskResource.new(@task).to_h }
      end

      def create
        task = current_user.created_tasks.build(task_params)

        if task.save
          render json: { task: TaskResource.new(task).to_h }, status: :created
        else
          render_errors(task)
        end
      end

      def update
        if @task.update(task_params)
          render json: { task: TaskResource.new(@task).to_h }
        else
          render_errors(@task)
        end
      end

      def destroy
        @task.destroy!
        head :no_content
      end

      private

      def set_task
        @task = Task.includes(:creator).find(params[:id])
      end

      def task_params
        params.expect(task: [ :title, :description, :completed, :due_on ])
      end
    end
  end
end
