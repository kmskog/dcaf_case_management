# Create, edit, and update patients. The main patient view is edit.
class PatientsController < ApplicationController
  include ActionController::Live
  before_action :confirm_admin_user, only: [:destroy]
  before_action :confirm_data_access, only: [:index]
  before_action :find_patient, if: :should_preload_patient_with_versions?
  rescue_from ActiveRecord::RecordNotFound,
              with: -> { redirect_to root_path }

  def index
    # n+1 join here
    respond_to do |format|
      format.csv do
        render_csv
      end
    end
  end

  def create
    patient = Patient.new patient_params

    if patient.save
      flash[:notice] = t('flash.new_patient_save')
      current_user.add_patient patient
    else
      flash[:alert] = t('flash.new_patient_error', error: patient.errors.full_messages.to_sentence)
    end

    redirect_to root_path
  end

  def edit
    # i18n-tasks-use t('activerecord.attributes.practical_support.confirmed')
    # i18n-tasks-use t('activerecord.attributes.practical_support.source')
    # i18n-tasks-use t('activerecord.attributes.practical_support.support_date')
    # i18n-tasks-use t('activerecord.attributes.practical_support.purchase_date')
    # i18n-tasks-use t('activerecord.attributes.practical_support.support_type')
    # i18n-tasks-use t('activerecord.attributes.external_pledge.active')
    # i18n-tasks-use t('activerecord.attributes.external_pledge.amount')
    # i18n-tasks-use t('activerecord.attributes.external_pledge.source')
    # i18n-tasks-use t('activerecord.attributes.fulfillment.audited')
    # i18n-tasks-use t('activerecord.attributes.fulfillment.check_number')
    # i18n-tasks-use t('activerecord.attributes.fulfillment.date_of_check')
    # i18n-tasks-use t('activerecord.attributes.fulfillment.fulfilled')
    # i18n-tasks-use t('activerecord.attributes.fulfillment.fund_payout')
    # i18n-tasks-use t('activerecord.attributes.fulfillment.gestation_at_procedure')
    # i18n-tasks-use t('activerecord.attributes.fulfillment.procedure_date')
    # i18n-tasks-use t('activerecord.attributes.practical_support.fulfilled')
    @note = @patient.notes.new
  end

  def update
    @patient.last_edited_by = current_user

    respond_to do |format|
      format.js do
        respond_to_update_for_js_format
      end
      format.json do
        respond_to_update_for_json_format
      end
    end
  end

  def data_entry
    @patient = Patient.new
  end

  def data_entry_create
    @patient = Patient.new patient_params

    if @patient.save
      flash[:notice] = t('flash.patient_save_success',
                         patient: @patient.name,
                         fund: current_tenant.name)
      redirect_to edit_patient_path @patient
    else
      flash[:alert] = t('flash.patient_save_error', error: @patient.errors.full_messages.to_sentence)
      render 'data_entry'
    end
  end

  def destroy
    if @patient.okay_to_destroy? && @patient.destroy
      flash[:notice] = t('flash.patient_removed_database')
      redirect_to authenticated_root_path
    else
      flash[:alert] = t('flash.patient_removed_database_error')
      redirect_to edit_patient_path(@patient)
    end
  end

  private

  # preload patient with versions for edit and js format update requests
  def should_preload_patient_with_versions?
    action_name.to_sym == :edit || (action_name.to_sym == :update && !request.format.json?)
  end


  def find_patient
    @patient = Patient.includes(versions: [:item, :user])
                      .find params[:id]
  end

  def find_patient_minimal
    @patient = Patient.find params[:id]
  end

  # requests from our autosave using jquery ($(form).submit()) use the js format
  def respond_to_update_for_js_format
    if @patient.update patient_params
      @patient = Patient.includes(versions: [:item, :user]).find(@patient.id) # reload
      flash.now[:notice] = t('flash.patient_info_saved', timestamp: Time.zone.now.display_timestamp)
    else
      error = @patient.errors.full_messages.to_sentence
      flash.now[:alert] = error
    end
  end

  # requests from our autosave using React (via the useFetch hook) use the json format
  def respond_to_update_for_json_format
    if @patient.update patient_params
      @patient.reload
      render json: {
        patient: @patient.reload.as_json,
        flash: {
          notice: t('flash.patient_info_saved', timestamp: Time.zone.now.display_timestamp)
        }
      }, status: :ok
    else
      render json: { flash: { alert: @patient.errors.full_messages.to_sentence } }, status: :unprocessable_entity
    end
  end

  PATIENT_DASHBOARD_PARAMS = [
    :name, :care_coordinator, 
    :procedure_date, :primary_phone, :pronouns, :status
  ].freeze

  PATIENT_INFORMATION_PARAMS = [
    :line_id,
    :legal_name, :email,
    :age, :race_ethnicity, :language, :voicemail_preference, :textable,
    :city, :state, :zipcode, :emergency_contact, :emergency_contact_phone,
    :emergency_contact_relationship,
    :emergency_contact_referencing,
    :employment_status, :income,
    :household_size_adults, :household_size_children, :insurance, :referred_by,
    :procedure_type,
    :emergency_disclosure, :advanced_care_directive, :call_911_permissions,
    { special_circumstances: [] },
    { in_case_of_emergency: [] }
  ].freeze

  # Does this make sense for a one to many relationship?
  PROCEDURE_INFORMATION_PARAMS = [
    :clinic_id,
    :surgeon_id, :procedure_type,
    :referred_to_clinic, 
    :solidarity, :solidarity_lead, :appointment_time,
    :multiday_appointment
  ].freeze

  # Does this make sense for a one to many relationship?
  PRACTICAL_SUPPORT_INFORMATION_PARAMS = [
    :practical_support_id, :street_address, :city, :state, :zipcode, :phone, :required_services
  ]

  FULFILLMENT_PARAMS = [
    fulfillment_attributes: [:id, :fulfilled, :procedure_date, 
                             :check_number, :date_of_check, :audited]
  ].freeze

  OTHER_PARAMS = [:shared_flag, :initial_call_date, :practical_support_waiver].freeze

  def patient_params
    permitted_params = [].concat(
      PATIENT_DASHBOARD_PARAMS, PATIENT_INFORMATION_PARAMS,
      PROCEDURE_INFORMATION_PARAMS, SHIFT_INFORMATION_PARAMS, OTHER_PARAMS
    )
    permitted_params.concat(FULFILLMENT_PARAMS) if current_user.allowed_data_access?
    params.require(:patient).permit(permitted_params)
  end

  def encrypt_payload(payload)
    encryptor = ActiveSupport::MessageEncryptor.new(ENV.fetch('PLEDGE_GENERATOR_ENCRYPTOR', '0' * 32))
    encryptor.encrypt_and_sign(payload)
  end

  def render_csv
    now = Time.zone.now.strftime('%Y%m%d')
    csv_filename = "patient_data_export_#{now}.csv"
    set_headers

    response.status = 200

    send_stream(filename: "#{csv_filename}") do |y|
      Patient.csv_header.each { |e| y.write e }
      Patient.to_csv.each { |e| y.write e }
      ArchivedPatient.to_csv.each { |e| y.write e }
    end
  end

  def set_headers
    headers['Content-Type'] = 'text/csv'
    headers['X-Accel-Buffering'] = 'no'
    headers['Cache-Control'] = 'no-cache'
    headers[Rack::ETAG] = nil # Without this, data doesn't stream
    headers.delete('Content-Length')
  end
end
