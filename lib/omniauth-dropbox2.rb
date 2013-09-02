require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Dropbox < OmniAuth::Strategies::OAuth2
      # Give your strategy a name.
      option :name, "dropbox"

      # This is where you pass the options you would pass when
      # initializing your consumer from the OAuth gem.
      option :client_options, {
        :site          => 'https://api.dropbox.com/1',
        :authorize_url => 'https://www.dropbox.com/1/oauth2/authorize',
        :token_url     => 'https://api.dropbox.com/1/oauth2/token',
      }

      # These are called after authentication has succeeded. If
      # possible, you should try to set the UID without making
      # additional calls (if the user id is returned with the token
      # or as a URI parameter). This may not be possible with all
      # providers.
      uid{ raw_info['uid'] }

      info do
        {
          :name => raw_info['display_name']
        }
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get('account/info').parsed
      end
    end
  end
end
