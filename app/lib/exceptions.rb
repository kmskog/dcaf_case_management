module Exceptions
  class UnauthorizedError < StandardError; end

  class NoGoogleGeoApiKeyError < StandardError; end

  class NoRegionsForFundError < StandardError; end
end
