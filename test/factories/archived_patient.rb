FactoryBot.define do
  factory :archived_patient do
    city
  intake_date { 400.days.ago }
  end
end
