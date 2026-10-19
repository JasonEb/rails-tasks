require "rails_helper"

RSpec.describe "Tasks API", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe "GET /api/v1/tasks" do
    it "lists every user's tasks, newest first" do
      mine = create(:task, creator: user, created_at: 2.hours.ago)
      theirs = create(:task, creator: other_user, created_at: 1.hour.ago)

      get "/api/v1/tasks", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json["tasks"].map { |t| t["id"] }).to eq([ theirs.id, mine.id ])
    end

    it "includes the creator and comment count" do
      create(:task, creator: other_user)

      get "/api/v1/tasks", headers: auth_headers(user)

      task = json["tasks"].first
      expect(task["creator"]).to eq("id" => other_user.id, "name" => other_user.name)
      expect(task["comments_count"]).to eq(0)
      expect(task).to include("title", "description", "completed", "due_on", "created_at", "updated_at")
    end

    it "returns 401 without a token" do
      get "/api/v1/tasks"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/tasks" do
    it "creates a task owned by the current user" do
      params = { task: { title: "Write specs", description: "Model first", due_on: "2026-11-01" } }

      expect { post "/api/v1/tasks", params: params, headers: auth_headers(user), as: :json }
        .to change(Task, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["task"]).to include("title" => "Write specs", "due_on" => "2026-11-01", "completed" => false)
      expect(Task.last.creator).to eq(user)
    end

    it "ignores a creator_id in the params" do
      params = { task: { title: "Sneaky", creator_id: other_user.id } }

      post "/api/v1/tasks", params: params, headers: auth_headers(user), as: :json

      expect(Task.last.creator).to eq(user)
    end

    it "returns 422 for a missing title" do
      post "/api/v1/tasks", params: { task: { title: "" } }, headers: auth_headers(user), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["title"]).to be_present
    end

    it "returns 400 when the task key is missing" do
      post "/api/v1/tasks", params: { title: "No wrapper" }, headers: auth_headers(user), as: :json

      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /api/v1/tasks/:id" do
    it "returns any user's task" do
      task = create(:task, creator: other_user)

      get "/api/v1/tasks/#{task.id}", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json["task"]["id"]).to eq(task.id)
    end

    it "returns 404 for a missing task" do
      get "/api/v1/tasks/0", headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/tasks/:id" do
    let(:task) { create(:task, creator: user, title: "Old") }

    it "lets the creator update the task" do
      patch "/api/v1/tasks/#{task.id}", params: { task: { title: "New", completed: true } },
                                        headers: auth_headers(user), as: :json

      expect(response).to have_http_status(:ok)
      expect(task.reload).to have_attributes(title: "New", completed: true)
    end

    it "returns 403 for another user and leaves the task unchanged" do
      patch "/api/v1/tasks/#{task.id}", params: { task: { title: "Hijacked" } },
                                        headers: auth_headers(other_user), as: :json

      expect(response).to have_http_status(:forbidden)
      expect(task.reload.title).to eq("Old")
    end

    it "returns 422 for invalid input" do
      patch "/api/v1/tasks/#{task.id}", params: { task: { title: "" } },
                                        headers: auth_headers(user), as: :json

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /api/v1/tasks/:id" do
    let!(:task) { create(:task, creator: user) }

    it "lets the creator delete the task" do
      expect { delete "/api/v1/tasks/#{task.id}", headers: auth_headers(user) }
        .to change(Task, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 403 for another user and keeps the task" do
      expect { delete "/api/v1/tasks/#{task.id}", headers: auth_headers(other_user) }
        .not_to change(Task, :count)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
