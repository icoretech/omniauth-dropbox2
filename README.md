# OmniAuth Dropbox2 Strategy

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

Auth hash includes:

- `uid`: Dropbox `account_id`
- `info[:name]`: Dropbox display name
- `extra['raw_info']`: full response from `users/get_current_account`

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

## Compatibility

- Ruby: `>= 3.2` (tested on `3.2`, `3.3`, `3.4`, `4.0`)
- `omniauth-oauth2`: `>= 1.8`, `< 1.9`
- Rails integration lanes: `~> 7.1.0`, `~> 7.2.0`, `~> 8.0.0`, `~> 8.1.0`

## Release

Tag releases as `vX.Y.Z`; GitHub Actions publishes the gem to RubyGems.

## License

MIT
