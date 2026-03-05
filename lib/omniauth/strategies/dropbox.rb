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

      credentials do
        {
          'token' => access_token.token,
          'refresh_token' => access_token.refresh_token,
          'expires_at' => access_token.expires_at,
          'expires' => access_token.expires?,
          'scope' => token_scope
        }.compact
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.post('users/get_current_account', body: 'null').parsed
      end

      def callback_url
        return '' if @authorization_code_from_signed_request

        options[:callback_url] || super
      end

      def query_string
        return '' if request.params['code']

        super
      end

      private

      def token_scope
        token_params = access_token.respond_to?(:params) ? access_token.params : {}
        token_params['scope'] || (access_token['scope'] if access_token.respond_to?(:[]))
      end
    end

    Dropbox2 = Dropbox
  end
end
