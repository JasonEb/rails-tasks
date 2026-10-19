require "rails_helper"

RSpec.describe "Users API", type: :request do
  describe "POST /api/v1/users" do
    let(:params) { { user: { email: "ada@example.com", name: "Ada", password: "password123" } } }

    it "creates a user and returns them with a token" do
      expect { post "/api/v1/users", params: params, as: :json }.to change(User, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["user"]).to include("email" => "ada@example.com", "name" => "Ada")
      expect(json["token"]).to eq(User.last.auth_token)
    end

    it "never returns the password digest" do
      post "/api/v1/users", params: params, as: :json

      expect(json["user"]).not_to have_key("password_digest")
    end

    it "returns 422 with errors for invalid input" do
      post "/api/v1/users", params: { user: { email: "", name: "", password: "short" } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to include("email", "name", "password")
    end

    it "returns 422 when the email is taken" do
      create(:user, email: "ada@example.com")

      post "/api/v1/users", params: params, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]["email"]).to be_present
    end
  end

  describe "GET /api/v1/me" do
    let(:user) { create(:user) }

    it "returns the current user" do
      get "/api/v1/me", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json["user"]).to include("id" => user.id, "email" => user.email)
    end

    it "returns 401 without a token" do
      get "/api/v1/me"

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to be_present
    end

    it "returns 401 with an unknown token" do
      get "/api/v1/me", headers: { "Authorization" => "Bearer nope" }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
