require "rails_helper"

RSpec.describe Task, type: :model do
  subject { build(:task) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_most(200) }
    it { is_expected.to validate_length_of(:description).is_at_most(10_000) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:creator).class_name("User") }
    it { is_expected.to have_many(:comments).dependent(:destroy) }
  end

  describe "defaults" do
    it "is not completed when created" do
      expect(Task.new.completed).to be(false)
    end

    it "starts with zero comments" do
      expect(create(:task).comments_count).to eq(0)
    end
  end

  describe ".newest_first" do
    it "orders tasks by creation time, newest first" do
      older = create(:task, created_at: 2.days.ago)
      newer = create(:task, created_at: 1.hour.ago)

      expect(Task.newest_first).to eq([ newer, older ])
    end
  end
end
