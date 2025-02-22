require 'test_helper'

class CitiesHelperTest < ActionView::TestCase
  include ERB::Util

  describe 'convenience methods' do
    it 'should return empty if not set' do
      assert_nil current_city
      assert_nil current_city_display
    end

    it 'should show a link if 2+ cities' do
      @cities = [
        create(:city, name: 'DC'),
        create(:city, name: 'MD'),
        create(:city, name: 'VA')
      ]

      @cities.each do |city|
        session[:city_id] = city.id
        session[:city_name] = city.name
        assert_equal current_city_display,
                     "<li><a class=\"nav-link navbar-text-alt\" href=\"/cities/new\">Your current city: #{session[:city_name]}</a></li>"
        assert_equal current_city, city
      end
    end

    it 'should show text if just one city' do
      city = create(:city, name: 'DC')
      session[:city_id] = city.id
      session[:city_name] = city.name
      assert_equal current_city_display,
                    "<li><span class=\"nav-link navbar-text-alt\">Your current city: #{session[:city_name]}</span></li>"
      assert_equal current_city, city
    end
  end
end
