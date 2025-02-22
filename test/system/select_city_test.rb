require 'application_system_test_case'

# Tests around city selection behavior
class SelectCityTest < ApplicationSystemTestCase
  before do
    @user = create :user
    create :city, name: 'New York'
    create :city, name: 'San Francisco'
    log_in @user
  end

  describe 'city selection process' do
    it 'should redirect to city selection page on login' do
      assert_equal current_path, new_city_path
      assert has_content? 'New York'
      assert has_content? 'San Francisco'
      assert has_button? 'Get started'
    end

    it 'should redirect to the main dashboard after city set' do
      choose 'New York'
      click_button 'Get started'
      assert_equal current_path, authenticated_root_path
      assert has_content? 'Your current city: New York'
    end
  end

  describe 'redirection conditions' do
    before { @patient = create :patient }
    it 'should redirect from dashboard if no city is set' do
      visit edit_patient_path(@patient) # no redirect
      assert_equal current_path, edit_patient_path(@patient)
      visit authenticated_root_path # back to dashboard
      assert_equal current_path, new_city_path
    end
  end
end
