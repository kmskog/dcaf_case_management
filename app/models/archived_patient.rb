# A PII stripped patient for reporting.
class ArchivedPatient < ApplicationRecord
  acts_as_tenant :fund

  # Concerns
  include PaperTrailable
  include Exportable

  # Relationships
  belongs_to :city
  belongs_to :clinic, optional: true
  has_one :fulfillment, as: :can_fulfill
  has_many :calls, as: :can_call
  
  # Enums
  enum :age_range, {
    not_specified: :not_specified,
    under_18: :under_18,
    age18_24: :age18_24,
    age25_34: :age25_34,
    age35_44: :age35_44,
    age45_54: :age45_54,
    age55plus: :age55plus,
    bad_value: :bad_value
  }

  # Validations
  validates :intake_date,
            :city,
            presence: true
  validates :procedure_date, format: /\A\d{4}-\d{1,2}-\d{1,2}\z/,
                               allow_blank: true
  # validates_associated :fulfillment

  # Archive & delete audited patients who called a several months ago, or any
  # from a year plus ago
  def self.archive_eligible_patients!
    Patient.all.each do |patient|
      next unless patient.archive_date < Date.today

      ActiveRecord::Base.transaction do
        ArchivedPatient.convert_patient(patient)
        patient.destroy!
      end
    end
  end


  def self.convert_patient(patient)
    archived_patient = new(
      city: patient.city,
      state: patient.state,
      intake_date: patient.intake_date,
      procedure_date: patient.procedure_date,
      multiday_appointment: patient.multiday_appointment,
      practical_support_waiver: patient.practical_support_waiver,

      shared_flag: patient.shared_flag,
      referred_by: patient.referred_by,
      referred_to_clinic: patient.referred_to_clinic,

      race_ethnicity: patient.race_ethnicity,
      employment_status: patient.employment_status,
      insurance: patient.insurance,
      procedure_type: patient.procedure_type,
      income: patient.income,
      language: patient.language,
      voicemail_preference: patient.voicemail_preference,

      textable: patient.textable,

      age_range: patient.age_range,
      has_alt_contact: patient.has_alt_contact,
      notes_count: patient.notes_count,
      has_special_circumstances: patient.has_special_circumstances
      has_in_case_of_emergency: patient.has_in_case_of_emergency
    )

    archived_patient.clinic_id = patient.clinic_id if patient.clinic_id
    archived_patient.city_id = patient.city_id

    PaperTrail.request(whodunnit: patient.created_by_id) do
      archived_patient.save!
    end

    patient.versions.destroy_all

    # patient.fulfillment.update! can_fulfill: archived_patient

    patient.calls.each do |call|
      call.update! can_call: archived_patient
    end
    patient.practical_supports.each do |support|
      support.update! can_support: archived_patient
    end

    archived_patient.save!
    archived_patient
  end
end
