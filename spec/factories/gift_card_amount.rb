FactoryBot.define do
  factory :gift_card_amount do
    value { Faker::Number.number(digits: 10) }
    association :gift_card_detail
  end
end
