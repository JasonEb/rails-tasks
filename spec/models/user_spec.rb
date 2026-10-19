require "rails_helper"

RSpec.describe User, type: :model do
  subject { build(:user) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
    it { is_expected.to have_secure_password }

    it "rejects a malformed email" do
      subject.email = "not-an-email"

      expect(subject).not_to be_valid
      expect(subject.errors[:email]).to be_present
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:created_tasks).class_name("Task").with_foreign_key(:creator_id).dependent(:destroy) }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
  end

  describe "email normalization" do
    it "strips and downcases the email before saving" do
      user = create(:user, email: "  Ada@Example.COM ")

      expect(user.email).to eq("ada@example.com")
    end
  end

  describe "auth token" do
    it "generates a unique token on create" do
      user = create(:user)

      expect(user.auth_token).to be_present
      expect(user.auth_token).not_to eq(create(:user).auth_token)
    end
  end
end
