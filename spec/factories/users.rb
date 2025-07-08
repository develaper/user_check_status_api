FactoryBot.define do
  factory :user do
    idfa { SecureRandom.uuid }
    ban_status { :not_banned }
  end
  
  factory :banned_user, parent: :user do
    ban_status { :banned }
  end
end
