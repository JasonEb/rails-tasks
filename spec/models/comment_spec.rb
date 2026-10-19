require "rails_helper"

RSpec.describe Comment, type: :model do
  subject { build(:comment) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:body) }
    it { is_expected.to validate_length_of(:body).is_at_most(5_000) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:task).counter_cache(true) }
    it { is_expected.to belong_to(:user) }
  end

  describe "counter cache" do
    it "keeps the task's comments_count in sync" do
      task = create(:task)

      comment = create(:comment, task: task)
      expect(task.reload.comments_count).to eq(1)

      comment.destroy
      expect(task.reload.comments_count).to eq(0)
    end
  end

  describe ".after_cursor" do
    it "returns comments with an id greater than the cursor" do
      task = create(:task)
      first, second, third = create_list(:comment, 3, task: task)

      expect(task.comments.after_cursor(first.id)).to contain_exactly(second, third)
      expect(task.comments.after_cursor(nil)).to contain_exactly(first, second, third)
    end
  end
end
