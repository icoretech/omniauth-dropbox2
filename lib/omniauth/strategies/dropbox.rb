# frozen_string_literal: true

require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    # OmniAuth strategy for Dropbox OAuth2.
    class Dropbox < OmniAuth::Strategies::OAuth2
      option :name, 'dropbox'

      option :client_options,
             site: 'https://api.dropboxapi.com/2',
             authorize_url: 'https://www.dropbox.com/oauth2/authorize',
             token_url: 'https://api.dropboxapi.com/oauth2/token',
             connection_opts: {
               headers: {
                 user_agent: 'icoretech-omniauth-dropbox2 gem',
                 accept: 'application/json',
                 content_type: 'application/json'
               }
             }

      uid { raw_info['account_id'] }

      info do
        {
          name: raw_info.dig('name', 'display_name')
        }.compact
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.post('users/get_current_account', body: '{}').parsed
      end

      def callback_url
        return '' if @authorization_code_from_signed_request

        options[:callback_url] || super
      end

      def query_string
        return '' if request.params['code']

        super
      end
    end

    Dropbox2 = Dropbox
  end
end
