require 'test_helper'
require_relative '../patient_test'

class PatientTest::Exportable < PatientTest
  before do
    # Perils of subclassing - this restores db to clean
    Patient.destroy_all
    ArchivedPatient.destroy_all
  end

  describe 'export concern methods' do
    before do
      @patient = create :patient
      @archived = create :archived_patient
    end

    describe 'get_region' do
      it 'should return the region name' do
        assert_equal @patient.region.name, @patient.get_region
      end
    end

    describe 'archived?' do
      it 'should return false if patient' do
        assert_not @patient.archived?
      end

      it 'should return true if archived' do
        assert @archived.archived?
      end
    end

    describe 'household size tests' do
      # get_household_size_children
      # get_household_size_adults
      it 'should return prefer not to answer with -1' do
        @patient.update household_size_children: -1, household_size_adults: -1
        assert_equal 'Prefer not to answer', @patient.get_household_size_children
        assert_equal 'Prefer not to answer', @patient.get_household_size_adults
      end

      it 'should return number otherwise' do
        @patient.update household_size_children: 4, household_size_adults: 3
        assert_equal 4, @patient.get_household_size_children
        assert_equal 3, @patient.get_household_size_adults
      end

      it 'should null out for archived patients' do
        archived = create :archived_patient
        assert_nil archived.get_household_size_children
        assert_nil archived.get_household_size_adults
      end
    end

    describe 'fulfillments related' do
      before do
        @patient.fulfillment.update fulfilled: true,
                                    procedure_date: 2.days.ago
      end

      describe 'fulfilled' do
        it 'should return fulfillment status' do
          assert @patient.fulfilled
          @patient.fulfillment.update fulfilled: false
          assert_not @patient.fulfilled
        end
      end

      describe 'procedure_date' do
        it 'should show procedure_date when fulfillment is set' do
          assert_equal 2.days.ago.to_date, @patient.procedure_date
        end
      end
    end

    describe 'call related' do
      before do
        @patient.calls.create attributes_for(:call, created_at: 5.days.ago, status: :reached_patient)
        @patient.calls.create attributes_for(:call, created_at: 3.days.ago, status: :left_voicemail)
        @patient.calls.create attributes_for(:call, created_at: 1.day.ago, status: :left_voicemail)
      end

      describe 'first_call_timestamp' do
        it 'should be nil if no calls' do
          @patient.calls.destroy_all
          assert_nil @patient.first_call_timestamp
        end

        it 'should return datetime of first call' do
          assert_equal 5.days.ago.to_date, @patient.first_call_timestamp.to_date
        end
      end

      describe 'last_call_timestamp' do
        it 'should be nil if no calls' do
          @patient.calls.destroy_all
          assert_nil @patient.last_call_timestamp
        end

        it 'should return datetime of last call' do
          assert_equal 1.day.ago.to_date, @patient.last_call_timestamp.to_date
        end
      end

      describe 'call_count' do
        it 'should return count of calls' do
          assert_equal 3, @patient.call_count
        end
      end

      describe 'reached_patient_call_count' do
        it 'should return count of reached calls' do
          assert_equal 1, @patient.reached_patient_call_count
        end
      end
    end

    describe 'export_clinic_name' do
      it 'should return nil if no clinic' do
        assert_nil @patient.export_clinic_name
      end

      it 'should return clinic name if set' do
        @clinic = create :clinic
        @patient.update clinic: @clinic
        assert_equal @clinic.name, @patient.export_clinic_name
      end
    end

    describe 'preferred language tests' do
      it 'should return the right language' do
        ['', nil].each do |language|
          @patient.update language: language
          assert_equal @patient.preferred_language, 'English'
        end

        @patient.update language: 'Spanish'
        assert_equal @patient.preferred_language, 'Spanish'
      end
    end

    describe 'all_practical_supports' do
      before do
        @patient.practical_supports.create attributes_for(:practical_support, confirmed: true, source: 'Friendship',
                                                                              support_type: 'Driving', amount: 50, fulfilled: true, attachment_url: 'google.com', purchase_date: 2.days.from_now)
        @patient.practical_supports.create attributes_for(:practical_support, confirmed: false, source: 'Friendship',
                                                                              support_type: 'Coffee', amount: 50, fulfilled: false, attachment_url: nil)
      end

      it 'should return nil if no practical supports' do
        @patient.practical_supports.destroy_all
        assert_equal '', @patient.all_practical_supports
      end

      it 'should return a joined list of practical supports' do
        assert_equal "Friendship - Driving - Confirmed - $50.00 - google.com - Fulfilled - Purchased on #{2.days.from_now.display_date}; Friendship - Coffee - Unconfirmed - $50.00 - No attachment - Not fulfilled - No purchase date",
                     @patient.all_practical_supports
      end
    end

    describe 'age range tests' do
      it 'should return the right age for numbers' do
        @patient.age = nil
        assert_equal @patient.age_range, :not_specified

        [15, 17].each do |age|
          @patient.update age: age
          assert_equal @patient.age_range, :under_18
        end

        [18, 20, 24].each do |age|
          @patient.update age: age
          assert_equal @patient.age_range, :age18_24
        end

        [25, 30, 34].each do |age|
          @patient.update age: age
          assert_equal @patient.age_range, :age25_34
        end

        [35, 40, 44].each do |age|
          @patient.update age: age
          assert_equal @patient.age_range, :age35_44
        end

        [45, 50, 54].each do |age|
          @patient.update age: age
          assert_equal @patient.age_range, :age45_54
        end

        [55, 60, 100].each do |age|
          @patient.update age: age
          assert_equal @patient.age_range, :age55plus
        end

        [101, 'yolo'].each do |bad_age|
          @patient.age = bad_age
          assert_equal @patient.age_range, :bad_value
        end
      end
    end

    describe 'get_field_value_for_serialization' do
      it 'should clean and return values' do
        @patient.update city: '=Cat Town'
        assert_equal "'=Cat Town", @patient.get_field_value_for_serialization(:city)
      end
    end
  end

  describe 'class methods' do
    describe 'csv_header' do
      it 'should generate correctly' do
        assert_equal ::Patient::CSV_EXPORT_FIELDS.keys.join(',') + "\n", Patient.csv_header.to_a[0]
      end
    end

    describe 'to_csv' do
      it 'should export patients' do
        create :patient
        create :patient
        data = Patient.to_csv.to_a
        # Not testing contents since that's very implementation-y
        assert_equal 2, data.to_a.length
      end

      it 'should export archived patients' do
        create :archived_patient
        data = ArchivedPatient.to_csv.to_a
        # Not testing contents since that's very implementation-y
        assert_equal 1, data.to_a.length
      end
    end
  end
end
