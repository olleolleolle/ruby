# Toplevel Pubnub module
module Pubnub
  # Validator module that holds all validators modules
  module Validator
    # Validator for Publish event
    module Subscribe
      class << self
        include CommonValidator

        def validate!
        end
      end
    end
  end
end
