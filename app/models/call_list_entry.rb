# Object representing a patient's call list.
class CallListEntry < ApplicationRecord
  acts_as_tenant :fund

  # Relationships
  belongs_to :user
  belongs_to :patient
  belongs_to :city

  # Validations
  validates :order_key, :city, presence: true
  validates_uniqueness_to_tenant :patient, scope: :user
end
