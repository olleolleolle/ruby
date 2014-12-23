# Toplevel Pubnub module
module Pubnub
  # Event module holds most basic and required infrastructure for every pubnub
  # event, there are also SingleEvent module and SubscribeEvent module
  module Event
    attr_reader :origin, :callback, :error_callback, :channel,
                :open_timeout, :read_timeout, :idle_timeout

    alias_method :channels, :channel

    def initialize(options, app)
      @app = app
      create_variables_from_options(app.env.merge(options))
      format_channels
      Pubnub.logger.debug('Pubnub') { "Initialized #{self.class}" }
    end

    def fire
      Pubnub.logger.debug('Pubnub') { "Fired event #{self.class}" }

      requester.mailbox << Celluloid::Actor.current

      Pubnub.logger.debug('Pubnub') { "Sent #{self.class} to requester" }

      message = receive do |msg|
        msg.is_a?(Net::HTTPResponse) || msg.is_a?(Message)
      end

      if message.is_a? Message::Stop

        Pubnub.logger.info('Pubnub') do
          "Stopped event #{self.class}: #{message.reason}"
        end

        message
      else
        envelopes = fire_callbacks(handle(message))
        finalize_event(envelopes)
        envelopes
      end
    end

    def uri
      uri  = @ssl ? 'https://' : 'http://'
      uri += @origin
      uri += path
      uri += '?' + Formatter.params_hash_to_url_params(parameters)
      Pubnub.logger.debug('Pubnub') { "Requested URI: #{uri}" }
      URI uri
    end

    private

    def format_channels
      @channel = Formatter.format_channel(@channel || @channels)
    end

    def fire_callbacks(envelopes)
      Pubnub.logger.debug('Pubnub') { "Firing callbacks for #{self.class}" }
      envelopes.each do |envelope|
        if !envelope.error && @callback && !envelope.timetoken_update
          @callback.call envelope
        end
        @error_callback.call envelope if envelope.error
      end
      envelopes
    end

    def parameters
      required = {
        pnsdk: "PubNub-Ruby/#{Pubnub::VERSION}"
      }

      empty_if_blank = {
        auth: @auth_key,
        uuid: @app.env[:uuid]
      }

      empty_if_blank.delete_if { |_k, v| v.blank? }

      required.merge(empty_if_blank)
    end

    def add_common_data_to_envelopes(envelopes, response)
      Pubnub.logger.debug('Pubnub') { 'Event#add_common_data_to_envelopes' }

      envelopes.each do |envelope|
        envelope.response      = response.body
        envelope.object        = response
        envelope.status        = response.code.to_i
        envelope.mark_as_timetoken
      end

      envelopes.last.last   = true if envelopes.last
      envelopes.first.first = true if envelopes.first

      envelopes
    end

    def handle(response)
      Pubnub.logger.debug('Pubnub') { 'Event#handle' }

      @response  = response
      @envelopes = format_envelopes response
    end

    def connection
      @app.connection_for(self)
    end

    def create_variables_from_options(options)
      variables = %w(origin channel channels message http_sync callback
                     connect_callback ssl cipher_key secret_key auth_key
                     publish_key subscribe_key timetoken error_callback
                     open_timeout read_timeout idle_timeout heartbeat)

      variables.each do |variable|
        instance_variable_set('@' + variable, options[variable.to_sym])
      end
    end

    def encode_state(state)
      URI.encode_www_form_component(state.to_json).gsub('+', '%20')
    end

    # It's a stub, proper format_envelopes methods are implemented in
    # corresponding event classes
    def format_envelopes(_response); end

    # It's a stub for events that have to do some additional stuff after
    # getting response
    def finalize_event(_envelopes); end

    # It's a stub, proper requester methods are in SingleEvent and
    # SubscribeEvent modules
    def requester; end
  end
end
