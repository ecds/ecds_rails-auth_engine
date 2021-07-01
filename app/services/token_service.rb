# frozen_string_literal: true

require 'jwt'
require 'httparty'

#
# Service to crate and verify JWTs
#
module TokenService
  class << self
    #
    # Generate new token
    #
    # @param [Login] login Login object for authenticating user.
    #
    # @return [String] Encrypted token with authenticating user's info.
    #
    def create(login)
      exp = Time.now.to_i + 4 * 3600
      exp_payload = { data: { who: login.who }, exp: exp }
      JWT.encode exp_payload,
                 'e4e554292baafabfa3adb2276d05fae98411a7d59335d87f5a9c6df806a2ba4bbbbd884fa1a05f159ac82d0a0f9371ba22a6a7b30df74333d717ac3ce69ea35e',
                 'HS256'
    end

    #
    # Verifies a token was generated by this application by decoding it.
    #
    # @param [String] token to be verified
    #
    # @return [Boolean, Array] Returns `false` if token is expired or invalid.
    #                          Otherwise, returns the contents of the token.
    #
    def verify(token)
      Rails.logger.debug "VERIFY TOKEN!!!!!! #{token}"
      key = 'e4e554292baafabfa3adb2276d05fae98411a7d59335d87f5a9c6df806a2ba4bbbbd884fa1a05f159ac82d0a0f9371ba22a6a7b30df74333d717ac3ce69ea35e'
      begin
        contents = JWT.decode token, key, true, algorithm: 'HS256'
      rescue JWT::ExpiredSignature
        return false # Handle expired token, e.g. logout user and/or deny access
      rescue JWT::VerificationError
        # Handle invalid token, e.g. logout user and/or deny access
        return false
      rescue JWT::DecodeError
        return false
      end
      contents
    end

    def verify_remote(params)
      remote_url = 'https://auth.digitalscholarship.emory.edu/tokens'
      response = HTTParty.post(generate_url(remote_url, access_token: params)).parsed_response
      if response.is_a?(String)
        YAML.load(response).symbolize_keys!
      else
        response[0]['data'].symbolize_keys!
      end
    end

    private

    def generate_url(url, params = {})
      uri = URI(url)
      uri.query = params.to_query
      uri.to_s
    end
  end
end