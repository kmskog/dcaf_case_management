require 'application_system_test_case'

# Confirm functional search and record lookup
class RecordLookupTest < ApplicationSystemTestCase
  before do
    @region = create :region
    @region2 = create :region
    @user = create :user
    log_in_as @user
  end

  describe 'looking up someone who exists', js: true do
    before do
      @patient = create :patient, name: 'Susan Everyteen DC',
                                  primary_phone: '111-222-3333',
                                  emergency_contact: 'Yolo Goat',
                                  emergency_contact_phone: '222-333-4455',
                                  region: @region

      @patient_2 = create :patient, name: 'Susan Everyteen MD',
                                    primary_phone: '111-222-4444',
                                    emergency_contact: 'Yolo Goat',
                                    emergency_contact_phone: '222-333-4455',
                                    region: @region2
    end

    it 'should have a functional search form' do
      assert_text 'Build your call list'
      assert has_button? 'Search'
      assert has_field? 'search'
    end

    it 'should retrieve and display a record' do
      fill_in 'search', with: 'susan everyteen'
      click_button 'Search'

      assert has_text? 'Search results'
      assert has_text? 'Susan Everyteen DC'
      assert_not has_text? 'Susan Everyteen MD'
      assert_text @patient.primary_phone_display
    end

    it 'should be able to retrieve a record based on other name' do
      fill_in 'search', with: 'Yolo Goat'
      click_button 'Search'

      assert has_text? 'Search results'
      assert has_text? 'Susan Everyteen DC'
      assert_not has_text? 'Susan Everyteen MD'
    end

    it 'should be able to retrieve a record based on other phone' do
      fill_in 'search', with: '222-333-4455'
      click_button 'Search'

      assert has_text? 'Search results'
      assert has_text? 'Susan Everyteen DC'
      assert_not has_text? 'Susan Everyteen MD'
    end

    it 'should be able to retrieve a record regardless of phone formatting' do
      fill_in 'search', with: '(111)2223333'
      click_button 'Search'

      assert has_text? 'Search results'
      assert has_text? 'Susan Everyteen DC'
      assert has_text? 'Add a new patient'
    end

    it 'should not pick up patients on other regions' do
      fill_in 'search', with: '111-222-4444'
      click_button 'Search'

      assert_not has_text? 'Susan Everyteen MD'
      within :css, '#search_results_shell' do
        assert has_text? 'Your search produced no results'
        assert has_text? 'Add a new patient'
        assert has_no_text? 'Search results'
      end
    end

    it 'should limit the number of patients returned' do
      16.times do |num|
        create :patient, primary_phone: "124-567-78#{num + 10}", region: @region
      end
      fill_in 'search', with: '124'
      click_button 'Search'

      assert_equal 15, page.all('tbody#search_results_content tr').count

      within :css, '#search_results_shell' do
        assert has_text? 'Add a new patient'
      end
    end

    # We haven't reached a UX agreement on this yet, but test is ready to go
    # it 'should display new patient partial even for the search results' do
    #   fill_in 'search', with: 'susan everyteen'
    #   click_button 'Search'

    #   assert has_text? 'Add a new patient'
    #   assert has_text? 'Search results'
    #   assert has_text? 'Susan Everyteen'
    # end
  end

  describe 'looking for someone who does not exist', js: true do
    it 'should display new patient partial with name' do
      fill_in 'search', with: 'Nobody Real Here'
      click_button 'Search'

      within :css, '#search_results_shell' do
        assert has_text? 'Your search produced no results'
        assert has_text? 'Add a new patient'
        assert_equal 'Nobody Real Here', find_field('Name').value
        assert has_no_text? 'Search results'
      end
    end

    it 'should display new patient partial with phone' do
      fill_in 'search', with: '111-111-1112'
      click_button 'Search'

      within :css, '#search_results_shell' do
        assert has_text? 'Your search produced no results'
        assert has_text? 'Add a new patient'
        assert_equal '111-111-1112', find_field('Phone').value
      end
    end
  end
end
