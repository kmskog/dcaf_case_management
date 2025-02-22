# Controller for rendering the home view and patient search.
class DashboardsController < ApplicationController
  include CitiesHelper
  include BudgetBarCalculable

  before_action :pick_city_if_not_set, only: [:index, :search]

  def index
    @shared_patients = eager_loaded_patients.shared_patients(current_city)
    @unconfirmed_support_patients = eager_loaded_patients.unconfirmed_practical_support(current_city)
  end

  def search
    @results = if params[:search].present?
                 eager_loaded_patients.search params[:search],
                                              cities: [current_city || City.all]
               else
                 []
               end

    @patient = Patient.new
    @today = Time.zone.today.to_date
    @phone = searched_for_phone?(params[:search]) ? params[:search] : ''
    @name = searched_for_name?(params[:search]) ? params[:search] : ''

    respond_to { |format| format.js }
  end

  def budget_bar
    # We call these by interpolation in the view; these comments are to let i18n-health know we're using them
    # i18n-tasks-use t('dashboard.budget_bar.pledged_item')
    # i18n-tasks-use t('dashboard.budget_bar.sent_item')
    render partial: 'dashboards/budget_bar',
           locals: budget_bar_calculations(current_city)
  end

  private

  def eager_loaded_patients
    Patient.includes([:calls, :fulfillment])
  end

  def searched_for_phone?(query)
    !/[a-z]/i.match query
  end

  def searched_for_name?(query)
    /[a-z]/i.match query
  end

  def pick_city_if_not_set
    redirect_to new_city_path if session[:city_id].blank?
  end
end
