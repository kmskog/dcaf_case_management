# Methods related to displaying attributes on the patient model
module AttributeDisplayable
  extend ActiveSupport::Concern

  def primary_phone_display
    return nil unless primary_phone.present?
    "#{primary_phone[0..2]}-#{primary_phone[3..5]}-#{primary_phone[6..9]}"
  end

  def emergency_contact_phone_display
    return nil unless emergency_contact_phone.present?
    "#{emergency_contact_phone[0..2]}-#{emergency_contact_phone[3..5]}-#{emergency_contact_phone[6..9]}"
  end

  def procedure_date_display
    return nil unless fulfillment.procedure_date.present?
    "#{fulfillment.procedure_date}"
  end

  def email_display
    return nil unless email.present?
    "#{email}"
  end
end
