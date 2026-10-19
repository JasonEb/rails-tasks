FactoryBot.define do
  factory :task do
    creator factory: :user
    sequence(:title) { |n| "Task #{n}" }
    description { "Something to do" }
  end
end
