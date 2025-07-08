class User < ApplicationRecord
  include BanStatusEnum
  
  UUID_FORMAT = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i

  validates :idfa, presence: true, uniqueness: true
  validates :idfa, format: { 
    with: UUID_FORMAT,
    message: "must be a valid UUID format"
  }
  validates :ban_status, presence: true

  has_many :integrity_logs, foreign_key: :idfa, primary_key: :idfa
end
