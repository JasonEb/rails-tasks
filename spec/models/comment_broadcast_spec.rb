require "rails_helper"

RSpec.describe "Comment broadcasts", type: :model do
  let(:task) { create(:task) }
  let(:stream) { "task:#{task.id}:comments" }

  it "broadcasts a created comment to the task's stream after commit" do
    expect { create(:comment, task: task, body: "Live!") }
      .to have_broadcasted_to(stream).with { |payload|
        expect(payload["type"]).to eq("comment.created")
        expect(payload["comment"]).to include("body" => "Live!", "task_id" => task.id)
        expect(payload["comment"]["user"]).to include("id", "name")
      }
  end

  it "broadcasts the id of a deleted comment" do
    comment = create(:comment, task: task)

    expect { comment.destroy }
      .to have_broadcasted_to(stream).with("type" => "comment.deleted", "comment" => { "id" => comment.id, "task_id" => task.id })
  end

  it "does not broadcast when the transaction rolls back" do
    expect {
      Comment.transaction do
        create(:comment, task: task)
        raise ActiveRecord::Rollback
      end
    }.not_to have_broadcasted_to(stream)
  end

  it "does not broadcast to other tasks' streams" do
    other_task = create(:task)

    expect { create(:comment, task: task) }
      .not_to have_broadcasted_to("task:#{other_task.id}:comments")
  end
end
