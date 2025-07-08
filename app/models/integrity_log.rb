class IntegrityLog < ApplicationRecord
  include BanStatusEnum
  
  validates :idfa, presence: true
  validates :ban_status, presence: true
  validates :ip, presence: true
  validates :country, presence: true
  
  scope :for_user, ->(idfa) { where(idfa: idfa) }
  scope :banned, -> { where(ban_status: :banned) }
  scope :not_banned, -> { where(ban_status: :not_banned) }
end
