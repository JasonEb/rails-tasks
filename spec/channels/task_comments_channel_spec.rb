require "rails_helper"

RSpec.describe TaskCommentsChannel, type: :channel do
  let(:user) { create(:user) }
  let(:task) { create(:task) }

  before { stub_connection current_user: user }

  it "streams the task's comments" do
    subscribe task_id: task.id

    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("task:#{task.id}:comments")
  end

  it "rejects a missing task" do
    subscribe task_id: 0

    expect(subscription).to be_rejected
  end

  it "rejects a subscription without a task_id" do
    subscribe

    expect(subscription).to be_rejected
  end

  describe ".stream_name" do
    it "names the stream after the task" do
      expect(described_class.stream_name(task)).to eq("task:#{task.id}:comments")
    end
  end
end
