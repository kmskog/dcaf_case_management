require "test_helper"

class CityTest < ActiveSupport::TestCase
  before { @city = create :city }

  describe 'validations' do
    it 'should build' do
      assert create(:city).valid?
    end

    [:name].each do |attrib|
      it "should require #{attrib}" do
        @city[attrib] = nil
        refute @city.valid?
      end
    end

    it 'should be unique on name within a fund' do
      create :city, name: 'New York'
      city2 = create :city
      assert city2.valid?
      city2.name = 'New York'
      refute city2.valid?

      ActsAsTenant.with_tenant(create(:fund)) do
        city3 = create :city, name: 'New York'
        assert city3.valid?
      end
    end
  end
end
