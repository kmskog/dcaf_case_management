FactoryBot.define do
  factory :call_list_entry do
    user
    patient
    city
    sequence :order_key
  end
end
