FactoryBot.define do
  factory :user do
    title { Faker::Lorem.sentence }
    body {Faker::Lorem.sentence }
  end
end