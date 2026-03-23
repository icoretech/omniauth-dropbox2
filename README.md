# OmniAuth Dropbox Strategy

[![Test](https://github.com/icoretech/omniauth-dropbox2/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/icoretech/omniauth-dropbox2/actions/workflows/test.yml?query=branch%3Amain)
[![Gem Version](https://badge.fury.io/rb/omniauth-dropbox2.svg)](https://badge.fury.io/rb/omniauth-dropbox2)

`omniauth-dropbox2` provides a Dropbox OAuth2 strategy for OmniAuth.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-dropbox2'
```

Then run:

```bash
bundle install
```

## Usage

Configure OmniAuth in your Rack/Rails app:

```ruby
use OmniAuth::Builder do
  provider :dropbox, ENV.fetch('DROPBOX_APP_KEY'), ENV.fetch('DROPBOX_APP_SECRET')
end
```

## Provider App Setup

- Dropbox app console: <https://www.dropbox.com/developers/apps>
- Register callback URL (example): `https://your-app.example.com/auth/dropbox/callback`

## Options

- Request-phase query options can be passed directly to `/auth/dropbox` when supported by Dropbox OAuth endpoints.

## Auth Hash

Example payload from `request.env['omniauth.auth']` (real flow shape, anonymized):

```json
{
  "uid": "dbid:sample-account-id",
  "info": {
    "name": "Sample User"
  },
  "credentials": {
    "token": "sample-access-token",
    "refresh_token": "sample-refresh-token",
    "expires": false,
    "scope": "files.metadata.read"
  },
  "extra": {
    "raw_info": {
      "account_id": "dbid:sample-account-id",
      "name": {
        "given_name": "Sample",
        "surname": "User",
        "familiar_name": "Sample",
        "display_name": "Sample User",
        "abbreviated_name": "SU"
      },
      "email": "sample@example.test",
      "email_verified": true,
      "disabled": false,
      "country": "IT",
      "locale": "en",
      "referral_link": "https://www.dropbox.com/referrals/AABsample",
      "is_paired": false,
      "account_type": {
        ".tag": "basic"
      },
      "root_info": {
        ".tag": "user",
        "root_namespace_id": "123456",
        "home_namespace_id": "123456"
      }
    }
  }
}
```

Notes:

- `uid` is mapped from `raw_info.account_id`
- `info.name` is mapped from `raw_info.name.display_name`
- `credentials` includes `token`, plus `refresh_token` when provided by Dropbox
- `extra.raw_info` is the full `users/get_current_account` response

## Development

```bash
bundle install
bundle exec rake
```

The default Rake task runs:

- `rake lint` (RuboCop)
- `rake test_unit` (strategy/unit Minitest suite)

Run Rails integration tests with an explicit Rails version:

```bash
RAILS_VERSION='~> 8.1.0' bundle install
RAILS_VERSION='~> 8.1.0' bundle exec rake test_rails_integration
```

## Test Structure

- `test/omniauth_dropbox2_test.rb`: strategy/unit behavior
- `test/rails_integration_test.rb`: full Rack/Rails request+callback flow
- `test/test_helper.rb`: shared test bootstrap

## Compatibility

- Ruby: `>= 3.2` (tested on `3.2`, `3.3`, `3.4`, `4.0`)
- `omniauth-oauth2`: `>= 1.8`, `< 2.0`
- Rails integration lanes: `~> 7.1.0`, `~> 7.2.0`, `~> 8.0.0`, `~> 8.1.0`

## Release

Tag releases as `vX.Y.Z`; GitHub Actions publishes the gem to RubyGems.

## License

MIT
