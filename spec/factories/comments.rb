FactoryBot.define do
  factory :comment do
    task
    user
    body { "Looks good to me" }
  end
end
