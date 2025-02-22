FactoryBot.define do
  factory :patient do
    name { 'New Patient' }
    sequence(:primary_phone, 100) { |n| "127-#{n}-1111" }
    city
    intake_date { 2.days.ago }
  end
end
