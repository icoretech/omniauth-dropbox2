# frozen_string_literal: true

require_relative 'test_helper'

require 'action_controller/railtie'
require 'cgi'
require 'json'
require 'logger'
require 'rack/test'
require 'rails'
require 'uri'
require 'webmock/minitest'

class RailsIntegrationSessionsController < ActionController::Base
  def create
    auth = request.env.fetch('omniauth.auth')
    render json: { uid: auth['uid'], name: auth.dig('info', 'name') }
  end

  def failure
    render json: { error: params[:message] }, status: :unauthorized
  end
end

class RailsIntegrationApp < Rails::Application
  config.root = File.expand_path('..', __dir__)
  config.eager_load = false
  config.secret_key_base = 'dropbox2-rails-integration-test-secret-key'
  config.hosts.clear
  config.hosts << 'example.org'
  config.logger = Logger.new(nil)

  config.middleware.use OmniAuth::Builder do
    provider :dropbox, 'client-id', 'client-secret'
  end

  routes.append do
    match '/auth/:provider/callback', to: 'rails_integration_sessions#create', via: %i[get post]
    get '/auth/failure', to: 'rails_integration_sessions#failure'
  end
end

RailsIntegrationApp.initialize! unless RailsIntegrationApp.initialized?

class RailsIntegrationTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    super
    @previous_test_mode = OmniAuth.config.test_mode
    @previous_allowed_request_methods = OmniAuth.config.allowed_request_methods
    @previous_request_validation_phase = OmniAuth.config.request_validation_phase

    OmniAuth.config.test_mode = false
    OmniAuth.config.allowed_request_methods = [:post]
    OmniAuth.config.request_validation_phase = nil
  end

  def teardown
    OmniAuth.config.test_mode = @previous_test_mode
    OmniAuth.config.allowed_request_methods = @previous_allowed_request_methods
    OmniAuth.config.request_validation_phase = @previous_request_validation_phase
    WebMock.reset!
    super
  end

  def app
    RailsIntegrationApp
  end

  def test_rails_request_and_callback_flow_returns_expected_auth_payload
    stub_dropbox_token_exchange
    stub_dropbox_current_account

    post '/auth/dropbox'

    assert_equal 302, last_response.status

    authorize_uri = URI.parse(last_response['Location'])

    assert_equal 'www.dropbox.com', authorize_uri.host
    state = CGI.parse(authorize_uri.query).fetch('state').first

    get '/auth/dropbox/callback', { code: 'oauth-test-code', state: state }

    assert_equal 200, last_response.status

    payload = JSON.parse(last_response.body)

    assert_equal 'dbid:rails-user', payload['uid']
    assert_equal 'Rails Test User', payload['name']

    assert_requested :post, 'https://api.dropboxapi.com/oauth2/token', times: 1
    assert_requested :post, 'https://api.dropboxapi.com/2/users/get_current_account', body: '{}', times: 1
  end

  private

  def stub_dropbox_token_exchange
    stub_request(:post, 'https://api.dropboxapi.com/oauth2/token').to_return(
      status: 200,
      headers: { 'Content-Type' => 'application/json' },
      body: { access_token: 'access-token', token_type: 'bearer' }.to_json
    )
  end

  def stub_dropbox_current_account
    stub_request(:post, 'https://api.dropboxapi.com/2/users/get_current_account')
      .with(body: '{}')
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: {
          account_id: 'dbid:rails-user',
          name: {
            display_name: 'Rails Test User'
          }
        }.to_json
      )
  end
end
