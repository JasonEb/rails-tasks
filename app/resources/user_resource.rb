class UserResource
  include Alba::Resource

  attributes :id, :email, :name, :created_at
end
