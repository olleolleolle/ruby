require 'json'
require 'base64'
require 'open-uri'
require 'openssl'
require 'celluloid'
require 'timers'
require 'net/http/persistent'
require 'logger'

require 'pubnub/version'
require 'pubnub/client'

# Adding blank? method to Object
class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  def present?
    !blank?
  end
end

# Toplevel Pubnub module
# TODO: YARDOC
module Pubnub
  class << self
    attr_accessor :logger, :client

    def new(options = {})
      Pubnub::Client.new(options)
    end
  end
end
