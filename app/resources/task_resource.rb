class TaskResource
  include Alba::Resource

  attributes :id, :title, :description, :completed, :due_on, :comments_count, :created_at, :updated_at

  one :creator do
    attributes :id, :name
  end
end
