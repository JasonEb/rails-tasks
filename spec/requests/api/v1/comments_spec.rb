require "rails_helper"

RSpec.describe "Comments API", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:task) { create(:task, creator: other_user) }

  describe "GET /api/v1/tasks/:task_id/comments" do
    it "lists the task's comments oldest first, with their authors" do
      first = create(:comment, task: task, user: user)
      second = create(:comment, task: task, user: other_user)
      create(:comment) # on another task

      get "/api/v1/tasks/#{task.id}/comments", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json["comments"].map { |c| c["id"] }).to eq([ first.id, second.id ])
      expect(json["comments"].first).to include("body", "task_id", "created_at")
      expect(json["comments"].first["user"]).to eq("id" => user.id, "name" => user.name)
    end

    it "pages with a limit and an after cursor" do
      comments = create_list(:comment, 3, task: task)

      get "/api/v1/tasks/#{task.id}/comments", params: { limit: 2 }, headers: auth_headers(user)

      expect(json["comments"].map { |c| c["id"] }).to eq(comments.first(2).map(&:id))
      expect(json["next_cursor"]).to eq(comments.second.id)

      get "/api/v1/tasks/#{task.id}/comments", params: { limit: 2, after: json["next_cursor"] },
                                               headers: auth_headers(user)

      expect(json["comments"].map { |c| c["id"] }).to eq([ comments.third.id ])
      expect(json["next_cursor"]).to be_nil
    end

    it "caps the limit at 100" do
      get "/api/v1/tasks/#{task.id}/comments", params: { limit: 1_000 }, headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json["limit"]).to eq(100)
    end

    it "returns 404 for a missing task" do
      get "/api/v1/tasks/0/comments", headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end

    it "returns 401 without a token" do
      get "/api/v1/tasks/#{task.id}/comments"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "POST /api/v1/tasks/:task_id/comments" do
    it "adds a comment by the current user to any task" do
      expect {
        post "/api/v1/tasks/#{task.id}/comments", params: { comment: { body: "On it" } },
                                                  headers: auth_headers(user), as: :json
      }.to change(task.comments, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["comment"]).to include("body" => "On it", "task_id" => task.id)
      expect(json["comment"]["user"]["id"]).to eq(user.id)
      expect(task.reload.comments_count).to eq(1)
    end

    it "broadcasts the new comment to the task's live stream" do
      expect {
        post "/api/v1/tasks/#{task.id}/comments", params: { comment: { body: "Hi all" } },
                                                  headers: auth_headers(user), as: :json
      }.to have_broadcasted_to("task:#{task.id}:comments").with(hash_including("type" => "comment.created"))
    end

    it "returns 422 for an empty body" do
      post "/api/v1/tasks/#{task.id}/comments", params: { comment: { body: "" } },
                                                headers: auth_headers(user), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["body"]).to be_present
    end

    it "returns 404 for a missing task" do
      post "/api/v1/tasks/0/comments", params: { comment: { body: "Hello" } },
                                       headers: auth_headers(user), as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/v1/comments/:id" do
    let!(:comment) { create(:comment, task: task, user: user) }

    it "lets the author delete their comment" do
      expect { delete "/api/v1/comments/#{comment.id}", headers: auth_headers(user) }
        .to change(Comment, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 403 for anyone else, including the task's creator" do
      expect { delete "/api/v1/comments/#{comment.id}", headers: auth_headers(other_user) }
        .not_to change(Comment, :count)

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 404 for a missing comment" do
      delete "/api/v1/comments/0", headers: auth_headers(user)

      expect(response).to have_http_status(:not_found)
    end
  end
end
