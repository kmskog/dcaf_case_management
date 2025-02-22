# Single-serving controller for setting current city for a user.
class CitiesController < ApplicationController
  def new
    @cities = ActsAsTenant.current_tenant.cities.sort_by(&:name)
    if @cities.count == 0
      raise Exceptions::NocitiesForFundError
    end

    if @cities.count == 1
      set_city_session @cities.first
      redirect_to authenticated_root_path
    end
    @cities
  end

  def create
    city = City.find params[:city_id]
    session[:city_id] = city.id
    redirect_to authenticated_root_path
  end

  private

  def set_city_session(city)
    session[:city_id] = city.id
  end
end
