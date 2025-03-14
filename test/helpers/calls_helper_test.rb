require 'test_helper'

class CallsHelperTest < ActionView::TestCase
  before do
    @patient = create :patient
    create_voicemail_config
  end

  describe 'voicemail link with warning' do
    it 'returns no voicemail notifier text if vm pref is set to no' do
      @patient.voicemail_preference = 'no'
      assert_match(/Do not leave this patient a voicemail/,
                   display_voicemail_link_with_warning(@patient))
      refute_match(/I left a voicemail for the patient/,
                   display_voicemail_link_with_warning(@patient))
    end

    it 'returns voicemail ok notifier text if vm pref is set to no' do
      @patient.voicemail_preference = 'yes'
      assert_match(/Okay to identify as CATF/,
                   display_voicemail_link_with_warning(@patient))
      assert_match(/I left a voicemail for the patient/,
                   display_voicemail_link_with_warning(@patient))
    end

    it 'returns voicemail not specified text if vm pref is set not spec' do
      @patient.voicemail_preference = 'not_specified'
      assert_match(/Do not identify as CATF/,
                   display_voicemail_link_with_warning(@patient))
      assert_match(/I left a voicemail for the patient/,
                   display_voicemail_link_with_warning(@patient))
    end

    it 'returns custom text if vm pref has a custom value' do
      @patient.voicemail_preference = 'Text Message Only'
      display_content = display_voicemail_link_with_warning(@patient)
      assert_match(/Text Message Only/, display_content)
      assert_match(/I left a voicemail for the patient/, display_content)
    end

    # this scenario will arise if an option is removed from the config
    # we want to keep the deleted config value with the patient (instead of
    # defaulting to a remaining config), and allow them to be updated as needed.
    it 'invalid voicemail preference is still displayed' do
      @patient.voicemail_preference = 'Unknown Voicemail Preference'
      display_content = display_voicemail_link_with_warning(@patient)
      assert_match(/Unknown Voicemail Preference/, display_content)
      assert_match(/I left a voicemail for the patient/, display_content)
    end
  end

  describe 'display other contact and phone if exists' do
    it 'returns other phone and other contact if set' do
      @patient.update emergency_contact: 'Yolo Goat',
                      emergency_contact_phone: '1112223333',
                      emergency_contact_relationship: 'Party'
      [/Yolo Goat/, /111-222-3333/, /Party/].each do |att|
        assert_match(att, display_emergency_contact_and_phone_if_exists(@patient))
      end
    end

    it 'returns empty if other phone and other contact are not set' do
      @patient.update emergency_contact: nil,
                      emergency_contact_phone: nil,
                      emergency_contact_relationship: nil
      assert_equal '', display_emergency_contact_and_phone_if_exists(@patient)
    end

    it 'returns other phone if other phone is set but other contact is not' do
      @patient.update emergency_contact: nil,
                      emergency_contact_phone: '1231231234',
                      emergency_contact_relationship: nil
      assert_match(/123-123-1234/, display_emergency_contact_and_phone_if_exists(@patient))
    end

    it 'returns other contact if other contact is set but other phone is not' do
      @patient.update emergency_contact: 'Foo Bar',
                      emergency_contact_phone: nil,
                      emergency_contact_relationship: nil
      assert_match(/Foo Bar/, display_emergency_contact_and_phone_if_exists(@patient))
    end
  end

  describe 'display_reached_patient_link' do
    it 'displays the reached patient button' do
      assert_match(/reached the patient/,
                   display_reached_patient_link(@patient))
    end
  end

  describe 'display couldnt reach patient link' do
    it 'displays the couldnt reach patient link' do
      assert_match(/couldn&#39;t reach/,
                   display_couldnt_reach_patient_link(@patient))
    end
  end
end
