class CommentResource
  include Alba::Resource

  attributes :id, :task_id, :body, :created_at, :updated_at

  one :user do
    attributes :id, :name
  end
end
