# Methods pertaining to patient search
module PatientSearchable
  extend ActiveSupport::Concern

  DEFAULT_SEARCH_LIMIT = 15

  class_methods do
    # Case insensitive and phone number format agnostic!
    # pass `search_limit: nil` for no limit.
    def search(name_or_phone_str, cities: nil, search_limit: DEFAULT_SEARCH_LIMIT)
      wildcard_name = "%#{name_or_phone_str}%"
      clean_phone = name_or_phone_str.gsub(/\D/, '')

      base = Patient
      if cities
        base = base.where(city: cities)
      end
      matches = base.where('name ilike ?', wildcard_name)
                    .or(base.where('emergency_contact ilike ?', wildcard_name))
                    .or(base.where('identifier ilike ?', wildcard_name))
      if clean_phone.present?
        clean_phone = "%#{clean_phone}%"
        matches = matches.or(base.where('primary_phone like ?', clean_phone))
                         .or(base.where('emergency_contact_phone like ?', clean_phone))
      end
      matches = matches.order(updated_at: :desc)
      matches = matches.limit(search_limit) if search_limit.present?
      matches
    end
  end
end
