FactoryBot.define do
  factory :event do
    event_type { :reached_patient }
    cm_name { 'Yolorita' }
    patient_name { 'Susan Everyteen' }
    patient_id { 'sdfghjk' }
    region
  end
end
