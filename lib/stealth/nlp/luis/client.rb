# frozen_string_literal: true

module Stealth
  module Nlp
    module Luis
      class Client < Stealth::Nlp::Client

        def initialize(subscription_key: nil, app_id: nil, endpoint: nil, datetime_ref: nil)
          begin
            @subscription_key = subscription_key || Stealth.config.luis.subscription_key
            @app_id = app_id || Stealth.config.luis.app_id
            @endpoint = endpoint || Stealth.config.luis.endpoint
            @datetime_ref = datetime_ref || Stealth.config.luis.datetime_reference
            @slot = Stealth.env.development? ? 'staging' : 'production'
          rescue NoMethodError
            raise(
              Stealth::Errors::ConfigurationError,
              'A `luis` configuration key must be specified directly or in `services.yml`'
            )
          end
        end

        def endpoint
          "https://#{@endpoint}/luis/prediction/v3.0/apps/#{@app_id}/slots/#{@slot}/predict"
        end

        def client
          @client ||= begin
            headers = {
              'Content-Type' => 'application/json'
            }
            HTTP.timeout(connect: 15, read: 60).headers(headers)
          end
        end

        def understand(query:)
          params = {
            'subscription-key'    => @subscription_key
          }

          body = MultiJson.dump({
            'query'               => query,
            'options'             => {
              'datetimeReference' => @datetime_ref,
            }
          })

          Stealth::Logger.l(
            topic: :nlp,
            message: 'Performing NLP lookup via Microsoft LUIS'
          )
          result = client.post(endpoint, params: params, body: body)
          Result.new(result: result)
        end

      end
    end
  end
end

ENTITY_TYPES = %i(number currency email percentage phone age
                        url ordinal geo dimension temp datetime duration)
