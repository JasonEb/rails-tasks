class User < ApplicationRecord
  EMAIL_FORMAT = URI::MailTo::EMAIL_REGEXP

  has_secure_password
  has_secure_token :auth_token

  has_many :created_tasks, class_name: "Task", foreign_key: :creator_id, inverse_of: :creator, dependent: :destroy
  has_many :comments, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: EMAIL_FORMAT, allow_blank: true }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, allow_nil: true
end
