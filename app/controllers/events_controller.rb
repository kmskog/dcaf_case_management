# For render
class EventsController < ApplicationController
  include CitiesHelper

  def index
    events = Event.where(city: current_city)
                  .order(created_at: :desc)

    @events = paginate_results(events)
    respond_to do |format|
      format.html { render partial: 'events/events' }
      format.js { render :layout => false }
    end
  end

  private

  def paginate_results(results)
    Kaminari.paginate_array(results)
            .page(params[:page])
            .per(25)
  end
end
