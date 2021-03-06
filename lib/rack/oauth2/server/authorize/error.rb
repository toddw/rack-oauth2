module Rack
  module OAuth2
    module Server
      class Authorize
        class BadRequest < Abstract::BadRequest
          attr_accessor :redirect_uri, :state, :protocol_params_location

          def protocol_params
            super.merge(:state => state)
          end

          def finish
            if redirect_uri.present? && protocol_params_location.present?
              super do |response|
                response.redirect Util.redirect_uri(redirect_uri, protocol_params_location, protocol_params)
              end
            else
              raise self
            end
          end
        end

        module ErrorMethods
          DEFAULT_DESCRIPTION = {
            :invalid_request => "The request is missing a required parameter, includes an unsupported parameter or parameter value, or is otherwise malformed.",
            :unauthorized_client => "The client is not authorized to use the requested response type.",
            :access_denied => "The end-user or authorization server denied the request.",
            :unsupported_response_type => "The requested response type is not supported by the authorization server.",
            :invalid_scope => "The requested scope is invalid, unknown, or malformed."
          }

          def self.included(klass)
            DEFAULT_DESCRIPTION.each do |error, default_description|
              klass.class_eval <<-ERROR
                def #{error}!(description = "#{default_description}", options = {})
                  bad_request! :#{error}, description, options
                end
              ERROR
            end
          end

          def bad_request!(error = :bad_request, description = nil, options = {})
            exception = BadRequest.new error, description, options
            exception.protocol_params_location = case response_type
            when :code
              :query
            when :token
              :fragment
            end
            exception.state = state
            exception.redirect_uri = verified_redirect_uri
            raise exception
          end
        end

        Request.send :include, ErrorMethods
      end
    end
  end
end