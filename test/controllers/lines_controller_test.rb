require 'test_helper'

# Test cities setting behavior
class CitiesControllerTest < ActionDispatch::IntegrationTest
  before do
    @user = create :user
    @city = create :city
    sign_in @user
  end

  describe 'new' do
    describe 'instance with multiple cities' do
      # Stub a second city
      before { create :city }

      it 'should return success' do
        get new_city_path
        assert_response :success
      end
    end

    describe 'instance with one city' do
      it 'should redirect to patient dashboard' do
        get new_city_path
        assert_redirected_to authenticated_root_path
        assert_equal @city.id, session[:city_id]
      end
    end

    describe 'instance with no cities' do
      it 'should raise an error' do
        @city.destroy
        assert_raises Exceptions::NoCitiesForFundError do
          get new_city_path
        end
      end
    end
  end

  describe 'create' do
    before do
      post cities_path, params: { city_id: @city.id }
    end

    it 'should set a session variable' do
      assert_equal @city.id, session[:city_id]
    end

    # TODO: Enforce city values
    # it 'should reject anything not set in cities' do
    # end
  end
end
