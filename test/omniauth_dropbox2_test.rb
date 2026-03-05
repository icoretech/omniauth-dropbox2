# frozen_string_literal: true

require_relative 'test_helper'

class OmniauthDropbox2Test < Minitest::Test
  def build_strategy
    OmniAuth::Strategies::Dropbox.new(nil, 'client-id', 'client-secret')
  end

  def test_uses_current_dropbox_endpoints
    client_options = build_strategy.options.client_options

    assert_equal 'https://api.dropboxapi.com/2', client_options.site
    assert_equal 'https://www.dropbox.com/oauth2/authorize', client_options.authorize_url
    assert_equal 'https://api.dropboxapi.com/oauth2/token', client_options.token_url
  end

  def test_uid_info_and_extra_are_derived_from_raw_info
    strategy = build_strategy
    payload = {
      'account_id' => 'dbid:abc123',
      'name' => {
        'display_name' => 'Test User'
      }
    }

    strategy.instance_variable_set(:@raw_info, payload)

    assert_equal 'dbid:abc123', strategy.uid
    assert_equal({ name: 'Test User' }, strategy.info)
    assert_equal({ 'raw_info' => payload }, strategy.extra)
  end

  def test_raw_info_posts_to_current_account_endpoint_and_memoizes
    strategy = build_strategy
    token = FakeAccessToken.new({ 'account_id' => 'dbid:cached' })

    strategy.define_singleton_method(:access_token) { token }

    first_call = strategy.raw_info
    second_call = strategy.raw_info

    assert_equal({ 'account_id' => 'dbid:cached' }, first_call)
    assert_same first_call, second_call
    assert_raw_info_post_call(token)
  end

  def test_credentials_include_refresh_token_even_when_token_does_not_expire
    strategy = build_strategy
    token = FakeCredentialAccessToken.new(
      token: 'access-token',
      refresh_token: 'refresh-token',
      expires_at: nil,
      expires: false,
      params: { 'scope' => 'files.metadata.read' }
    )

    strategy.define_singleton_method(:access_token) { token }

    assert_equal(
      {
        'token' => 'access-token',
        'refresh_token' => 'refresh-token',
        'expires' => false,
        'scope' => 'files.metadata.read'
      },
      strategy.credentials
    )
  end

  def test_callback_url_prefers_configured_value
    strategy = build_strategy
    callback = 'https://example.test/auth/dropbox/callback'
    strategy.options[:callback_url] = callback

    assert_equal callback, strategy.callback_url
  end

  def test_callback_url_is_blank_for_signed_request_flow
    strategy = build_strategy
    strategy.instance_variable_set(:@authorization_code_from_signed_request, true)

    assert_equal '', strategy.callback_url
  end

  def test_query_string_is_ignored_during_callback_request
    strategy = build_strategy
    request = Rack::Request.new(Rack::MockRequest.env_for('/auth/dropbox/callback?code=abc&state=xyz'))
    strategy.define_singleton_method(:request) { request }

    assert_equal '', strategy.query_string
  end

  def test_query_string_is_kept_for_non_callback_requests
    strategy = build_strategy
    request = Rack::Request.new(Rack::MockRequest.env_for('/auth/dropbox?prompt=consent'))
    strategy.define_singleton_method(:request) { request }

    assert_equal '?prompt=consent', strategy.query_string
  end

  def test_does_not_expose_wrong_omniauth_box2_namespace
    assert_raises(NameError) { Omniauth::Box2::VERSION }
  end

  private

  def assert_raw_info_post_call(token)
    assert_equal 1, token.calls.length
    assert_equal 'users/get_current_account', token.calls.first[:path]
    assert_equal 'null', token.calls.first[:body]
  end

  class FakeAccessToken
    attr_reader :calls

    def initialize(parsed_payload)
      @parsed_payload = parsed_payload
      @calls = []
    end

    def post(path, body: nil, headers: nil)
      @calls << { path: path, body: body, headers: headers }
      Struct.new(:parsed).new(@parsed_payload)
    end
  end

  class FakeCredentialAccessToken
    attr_reader :token, :refresh_token, :expires_at, :params

    def initialize(token:, refresh_token:, expires_at:, expires:, params:)
      @token = token
      @refresh_token = refresh_token
      @expires_at = expires_at
      @expires = expires
      @params = params
    end

    def expires?
      @expires
    end

    def [](key)
      { 'scope' => @params['scope'] }[key]
    end
  end
end
