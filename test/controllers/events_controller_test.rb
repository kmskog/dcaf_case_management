require 'test_helper'

class EventsControllerTest < ActionDispatch::IntegrationTest
  before do
    @user = create :user
    city = create :city
    sign_in @user
    choose_city city
  end

  describe 'index method' do
    before do
      get events_path
    end

    it 'should return success' do
      assert_response :success
    end
  end
end
