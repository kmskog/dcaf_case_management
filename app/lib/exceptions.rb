module Exceptions
  class UnauthorizedError < StandardError; end

  class NoGoogleGeoApiKeyError < StandardError; end

  class NoCitiesForFundError < StandardError; end
end
