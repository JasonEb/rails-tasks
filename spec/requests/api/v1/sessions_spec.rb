require "rails_helper"

RSpec.describe "Sessions API", type: :request do
  describe "POST /api/v1/sessions" do
    let!(:user) { create(:user, email: "ada@example.com", password: "password123") }

    it "returns the user and token for valid credentials" do
      post "/api/v1/sessions", params: { email: "ada@example.com", password: "password123" }, as: :json

      expect(response).to have_http_status(:ok)
      expect(json["token"]).to eq(user.auth_token)
      expect(json["user"]["id"]).to eq(user.id)
    end

    it "matches the email case-insensitively" do
      post "/api/v1/sessions", params: { email: "ADA@example.com", password: "password123" }, as: :json

      expect(response).to have_http_status(:ok)
    end

    it "returns 401 for a wrong password" do
      post "/api/v1/sessions", params: { email: "ada@example.com", password: "wrong" }, as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json).not_to have_key("token")
    end

    it "returns 401 for an unknown email" do
      post "/api/v1/sessions", params: { email: "nobody@example.com", password: "password123" }, as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
