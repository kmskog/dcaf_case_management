FactoryBot.define do
  factory :city do
    sequence :name do |n|
      "City#{n}"
    end
    fund
  end
end
