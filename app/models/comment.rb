class Comment < ApplicationRecord
  belongs_to :task, counter_cache: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 5_000 }

  scope :oldest_first, -> { order(:id) }
  scope :after_cursor, ->(cursor) { cursor.present? ? where(id: (cursor.to_i + 1)..) : all }
end
