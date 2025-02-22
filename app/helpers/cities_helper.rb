# Convenience function for displaying cities around the app.
module CitiesHelper
  def current_city_display
    return if !session[:city_id]

    # If multiple cities, link to the switcher
    if City.count > 1
      return content_tag :li do
        link_to t('navigation.current_city.helper') + ": #{current_city.name}",
                new_city_path,
                class: 'nav-link navbar-text-alt'
      end
    end

    # Otherwise just display the content
    content_tag :li do
      content_tag :span, t('navigation.current_city.helper') + ": #{current_city.name}",
                         class: 'nav-link navbar-text-alt'
    end
  end

  def current_city
    City.find_by_id session[:city_id]
  end
end
