# Set up fixtures and database seeds to simulate a production environment.
raise 'No running seeds in prod' unless [nil, 'Sandbox'].include? ENV['DARIA_FUND']

# Clear out existing DB
ActsAsTenant.without_tenant do
  Config.destroy_all
  Event.destroy_all
  Call.destroy_all
  CallListEntry.destroy_all
  Fulfillment.destroy_all
  Note.destroy_all
  Patient.destroy_all
  ArchivedPatient.destroy_all
  User.destroy_all
  Clinic.destroy_all
  PaperTrailVersion.destroy_all
  ActiveRecord::SessionStore::Session.destroy_all
  Region.destroy_all
  PracticalSupport.destroy_all
  Fund.destroy_all
end

# Do versioning
PaperTrail.enabled = true

# Set a few config constants
note_text = 'This is a note ' * 10
additional_note_text = 'Additional note ' * 10
password = 'AbortionsAreAHumanRight1'

# Create a few test funds
fund1 = Fund.create! name: 'SBF',
                     domain: 'petfinder.com',
                     subdomain: 'sandbox',
                     full_name: 'Sand Box Fund',
                     site_domain: 'www.petfinder.com',
                     phone: '202-452-7464'

fund2 = Fund.create! name: 'CatFund',
                     domain: 'petfinder.com',
                     subdomain: 'catbox',
                     full_name: 'Cat Fund',
                     site_domain: 'www.petfinder.com',
                     phone: '(281) 330-8004'

[fund1, fund2].each do |fund|
  ActsAsTenant.with_tenant(fund) do
    regions = if fund == fund1
              ['Main', 'Spanish'].map { |region| Region.create! name: region }
            else
              ['Maru', 'Guremike'].map { |region| Region.create! name: region }
            end

    # Create test users
    user = User.create! name: 'testuser (admin)', email: 'test@example.com',
                        password: password, password_confirmation: password,
                        role: :admin
    user2 = User.create! name: 'testuser two', email: 'test2@example.com',
                         password: password, password_confirmation: password,
                         role: :cm
    User.create! name: 'testuser three', email: 'test3@example.com',
                 password: password, password_confirmation: password,
                 role: :cm

    # Default to user2 as the actor
    PaperTrail.request.whodunnit = user2.id

    # Create a few clinics
    Clinic.create! name: 'Sample Clinic 1 - DC', street_address: '1600 Pennsylvania Ave',
                   city: 'Washington', state: 'DC', zip: '20500'
    Clinic.create! name: 'Sample Clinic 2 - VA', street_address: '1400 Defense',
                   city: 'Arlington', state: 'VA', zip: '20301'
    Clinic.create! name: 'Sample Clinic with NAF', street_address: '815 V Street NW',
                   city: 'Washington', state: 'DC', zip: '20001'
    Clinic.create! name: 'Sample Clinic without NAF', street_address: '1811 14th Street NW',
                   city: 'Washington', state: 'DC', zip: '20009', accepts_medicaid: true

    # Create user-settable configuration
    Config.create config_key: :insurance,
                  config_value: { options: ['DC Medicaid', 'MD Medicaid', 'VA Medicaid', 'Other Insurance'] }
    Config.create config_key: :language,
                  config_value: { options: %w[Spanish French Korean] }
    Config.create config_key: :resources_url,
                  config_value: { options: ['https://www.petfinder.com/cats/'] }
    Config.create config_key: :practical_support_guidance_url,
                  config_value: { options: ['https://www.petfinder.com/dogs/'] }
    Config.create config_key: :referred_by,
                  config_value: { options: ['Metal band'] }
    Config.create config_key: :fax_service,
                  config_value: { options: ['https://www.efax.com'] }
    Config.create config_key: :start_of_week,
                  config_value: { options: ['Monday'] }

    # Create ten active patients with generic info.
    10.times do |i|
      patient = Patient.create! name: "Patient #{i}",
                                primary_phone: "123-123-123#{i}",
                                intake_date: 3.days.ago,
                                shared_flag: i.even?,
                                region: regions.first

      # Create associated objects
      case i
      when 0
        10.times do
          patient.calls.create! status: :reached_patient,
                                created_at: 3.days.ago
        end
      when 1
        PaperTrail.request(whodunnit: user.id) do
          patient.update! name: 'Other Contact info - 1', emergency_contact: 'Jane Doe',
                          emergency_contact_phone: '234-456-6789', emergency_contact_relationship: 'Sister'
          patient.calls.create! status: :reached_patient,
                                created_at: 14.hours.ago
        end
      when 2
        # appointment one week from today && clinic selected
        patient.update! name: 'Clinic and Appt - 2',
                        zipcode: "20009",
                        pronouns: 'she/they',
                        clinic: Clinic.first,
                        procedure_date: 2.days.from_now
      when 4
        PaperTrail.request(whodunnit: user.id) do
          # With special circumstances
          patient.update! name: 'Special Circumstances - 4',
                          special_circumstances: ['Prison', 'Fetal anomaly']
          # And a recent call on file
          patient.calls.create! status: :left_voicemail
        end
      end

      if i != 9
        5.times do
          patient.calls.create! status: :left_voicemail,
                                created_at: 3.days.ago
        end
      end

      # Add notes for most patients
      unless [0, 1].include? i
        patient.notes.create! full_text: note_text
      end

      if i.even?
        patient.notes.create! full_text: additional_note_text
        patient.practical_supports.create! support_type: 'Advice', source: 'Counselor', start_time: (Time.now + rand(10).days), end_time: (Time.now - rand(10).days + 4.hours)
      end

      if i % 3 == 0
        patient.practical_supports.create! support_type: 'Car rides', source: 'Neighbor', 
                                            start_time: 3.days.from_now, end_time: 4.days.from_now
      end

      if i % 5 == 0
        patient.practical_supports.create! support_type: 'Hotel', source: 'Donation', amount: 100
      end

      # Add select patients to call list for user
      user.add_patient patient if [0, 1, 2, 3, 4, 5].include? i

      patient.save
    end

    # Add patients for reporting purposes - CSV exports, fulfillments, etc.
    PaperTrail.request.whodunnit = user.id
    10.times do |i|
      patient = Patient.create!(
        name: "Reporting Patient #{i}",
        primary_phone: "321-0#{i}0-001#{rand(10)}",
        intake_date: 3.days.ago,
        shared_flag: i.even?,
        region: i.even? ? regions.first : regions.second,
        clinic: Clinic.all.sample,
        procedure_date: 10.days.from_now,
        
      )

      next unless i.even?

      patient.fulfillment.update fulfilled: true,
                                 procedure_date: 10.days.from_now
    end

    (1..5).each do |patient_number|
      patient = Patient.create!(
        name: "Reporting Patient #{patient_number}",
        primary_phone: "321-0#{patient_number}0-002#{rand(10)}",
        intake_date: 3.days.ago,
        shared_flag: patient_number.even?,
        region: regions[patient_number % 3] || regions.first,
        clinic: Clinic.all.sample,
        procedure_date: 10.days.from_now
      )

      # reached within the past 30 days
      5.times do
        patient.calls.create! status: :reached_patient,
                              created_at: (Time.now - rand(10).days)
        patient.calls.create! status: :reached_patient,
                              created_at: (Time.now - rand(10).days - 10.days)
      end
    end

    (1..5).each do |patient_number|
      patient = Patient.create!(
        name: "Old Reporting Patient #{patient_number}",
        primary_phone: "321-0#{patient_number}0-003#{rand(10)}",
        intake_date: 3.days.ago,
        shared_flag: patient_number.even?,
        region: regions[patient_number % 3] || regions.first,
        clinic: Clinic.all.sample,
        procedure_date: 10.days.from_now
      )

      5.times do
        patient.calls.create! status: :reached_patient,
                              created_at: (Time.now - rand(10).days - 6.months)
      end
    end

    (1..5).each do |patient_number|
      Patient.create!(
        name: "Pledge Reporting Patient #{patient_number}",
        primary_phone: "321-0#{patient_number}0-004#{rand(10)}",
        intake_date: 3.days.ago,
        shared_flag: patient_number.even?,
        region: regions[patient_number % 3] || regions.first,
        clinic: Clinic.all.sample,
        procedure_date: 10.days.from_now,

      )
    end

    # Add patients for archiving purposes with ALL THE INFO
    (1..2).each do |patient_number|
      # initial create data from voicemail
      patient = Patient.create!(
        name: "Archive Dataful Patient #{patient_number}",
        primary_phone: "321-0#{patient_number}0-005#{rand(10)}",
        voicemail_preference: 'yes',
        region: regions.first,
        language: 'Spanish',
        intake_date: 140.days.ago,
        created_at: 140.days.ago
      )

      # Call, but no answer. leave a VM.
      patient.calls.create status: :left_voicemail, created_at: 139.days.ago

      # Call, which updates patient info, maybe flags shared, make a note.
      patient.calls.create status: :reached_patient, created_at: 138.days.ago

      patient.update!(
        # header info - hand filled in
        procedure_date: 130.days.ago,

        # patient info - hand filled in
        age: 24,
        race_ethnicity: 'Hispanic/Latino',
        city: 'Washington',
        state: 'DC',
        county: 'Washington',
        emergency_contact: 'Susie Q.',
        emergency_contact_phone: "555-0#{patient_number}0-0053",
        emergency_contact_relationship: 'Mother',
        employment_status: 'Student',
        income: '$10,000-14,999',
        household_size_adults: 3,
        household_size_children: 2,
        insurance: 'Other Insurance',
        referred_by: 'Clinic',
        special_circumstances: ['', '', 'Homelessness', '', '', 'Other medical issue', '', '', ''],

        # abortion info - hand filled in
        clinic: Clinic.all.sample,
        referred_to_clinic: patient_number.odd?,
        
        updated_at: 138.days.ago # not sure if this even works?
      )

      # toggle shared flag, maybe
      patient.update!(
        shared_flag: patient_number.odd?,
        updated_at: 137.days.ago
      )

      # generate notes
      patient.notes.create!(
        full_text: 'One note, with iffy PII! This one was from the first call!',
        created_at: 137.days.ago
      )

      # another call. get abortion information, create pledges, a note.
      patient.calls.create! status: :reached_patient, created_at: 136.days.ago

      # notes tab
      PaperTrail.request(whodunnit: user2.id) do
        patient.notes.create!(
          full_text: 'Two note, maybe with iffy PII! From the second call.',
          created_at: 133.days.ago
        )
      end

      # fulfillment
      patient.fulfillment.update!(
        fulfilled: true,
        procedure_date: 130.days.ago,
        updated_at: 125.days.ago
      )
    end

    (1..2).each do |patient_number|
      # Create dropoff patients
      patient = Patient.create!(
        name: "Archive Dropoff Patient #{patient_number}",
        primary_phone: "867-9#{patient_number}0-004#{rand(10)}",
        voicemail_preference: 'yes',
        region: regions.first,
        language: 'Spanish',
        intake_date: 640.days.ago,
        created_at: 640.days.ago
      )

      # Call, but no answer. leave a VM.
      patient.calls.create status: :left_voicemail, created_at: 639.days.ago

      # Call, which updates patient info, maybe flags, make a note.
      patient.calls.create status: :reached_patient, created_at: 138.days.ago

      # Patient 1 drops off immediately
      next if patient_number.odd?

      # We reach Patient 2
      patient.update!(
        # header info - hand filled in
        procedure_date: 630.days.ago,

        # patient info - hand filled in
        age: 24,
        race_ethnicity: 'Hispanic/Latino',
        city: 'Washington',
        state: 'DC',
        county: 'Washington',
        zipcode: "20009",
        pronouns: 'they/them',
        emergency_contact: 'Susie Q.',
        emergency_contact_phone: "555-6#{patient_number}0-0053",
        emergency_contact_relationship: 'Mother',

        employment_status: 'Student',
        income: '$10,000-14,999',
        household_size_adults: 3,
        household_size_children: 2,
        insurance: 'Other Insurance',
        referred_by: 'Clinic',
        special_circumstances: ['', '', 'Homelessness', '', '', 'Other medical issue', '', '', ''],

        # abortion info - hand filled in
        clinic: Clinic.all.sample,
        referred_to_clinic: patient_number.odd?
      )

      # toggle flag, maybe
      patient.update!(
        shared_flag: patient_number.odd?,
        updated_at: 637.days.ago
      )

      # generate notes
      patient.notes.create!(
        full_text: 'One note, with iffy PII! This one was from the first call!',
        created_at: 637.days.ago
      )
    end

    # A few specific named cases that reflect common scenarios
    regina = Patient.create! name: 'Regina (SCENARIO)',
                             region: regions.first,
                             primary_phone: "000-000-0001",
                             intake_date: 30.days.ago
    regina.calls.create! created_at: 30.days.ago,
                         status: 'reached_patient'
    regina.update procedure_date: 18.days.ago,
                  clinic: Clinic.first

    regina.calls.create! created_at: 22.days.ago,
                         status: 'reached_patient'
    regina.fulfillment.update fulfilled: true,
                              procedure_date: 18.days.ago

    regina.notes.create! full_text: "SCENARIO: Regina calls us at 6 weeks LMP on 3-12. We call her back and reach the patient. We explain the fund's policies of only funding after 7 weeks LMP. Regina’s options are to either schedule her appointment a week from the day she calls or fund her procedure on her own. We offer her references to clinics who will be able to see her and the number to other funders who may be able to help her. We emphasize although we cannot fund her now financially, we can in the future and she should call us back if that is the case. She says she will make an appointment for two weeks out. Regina calls us back on 3-20. Her funding is completed. We send the pledge to the clinic on Regina's behalf. Regina goes to her appointment on 3-24 and has her abortion. The clinic mails us back the completed pledge form on 4-15. Fund checks the pledge against our system, completes an entry in our ledger, notes the completed pledge on Regina's file in DARIA (which then anon’s her data eventually), writes a check to the clinic and mails the check it to the clinic."

    janis = Patient.create! name: 'Janis (SCENARIO)',
                            region: regions.first,
                            primary_phone: "000-000-0002",
                            intake_date: 40.days.ago
    janis.calls.create! created_at: 40.days.ago,
                        status: 'left_voicemail'
    janis.calls.create! created_at: 40.days.ago,
                        status: 'left_voicemail'
    janis.calls.create! created_at: 39.days.ago,
                        status: 'left_voicemail'
    janis.calls.create! created_at: 40.days.ago,
                        status: 'couldnt_reach_patient'
    janis.notes.create full_text: "SCENARIO: Janis calls us on 6-17. We call her back and leave a voicemail. We try again at the end of the night, but do not reach her. Janis calls us back on 6-18. We return her call and leave a voicemail. Janis calls us back on 6-24. We return her call, but her voicemail is turned off. We do not hear from Janis again."
  end
end

# Log results
ActsAsTenant.without_tenant do
  puts "Seed completed! \n" \
       "Inserted #{Config.count} Config objects. \n" \
       "Inserted #{Event.count} Event objects. \n" \
       "Inserted #{Call.count} Call objects. \n" \
       "Inserted #{CallListEntry.count} CallListEntry objects. \n" \
       "Inserted #{Fulfillment.count} Fulfillment objects. \n" \
       "Inserted #{Note.count} Note objects. \n" \
       "Inserted #{Patient.count} Patient objects. \n" \
       "Inserted #{ArchivedPatient.count} ArchivedPatient objects. \n" \
       "Inserted #{User.count} User objects. \n" \
       "Inserted #{Clinic.count} Clinic objects. \n" \
       "Inserted #{Fund.count} Fund objects. \n" \
       'User credentials are as follows: ' \
       "EMAIL: #{User.where(role: :admin).first.email} PASSWORD: #{password}"
end
