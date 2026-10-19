class Task < ApplicationRecord
  belongs_to :creator, class_name: "User", inverse_of: :created_tasks
  has_many :comments, dependent: :destroy

  validates :title, presence: true, length: { maximum: 200 }
  validates :description, length: { maximum: 10_000 }

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
end
