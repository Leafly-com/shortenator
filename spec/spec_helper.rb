# frozen_string_literal: true

require 'bundler/setup'
require 'shortenator'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

require 'vcr'
require 'webmock/rspec'

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock

  config.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: %i[method path]
  }

  # config.allow_http_connections_when_no_cassette = true
  # config.debug_logger = $stdout

  # Only want VCR to intercept requests to external URLs.
  config.ignore_localhost = true
  config.ignore_hosts 'json-schema.org'

  config.configure_rspec_metadata!
end

class << VCR
  prepend Module.new {
    def turned_off(webmock_options: {}, vcr_options: {})
      WebMock.allow_net_connect!(webmock_options)
      super(vcr_options)
    ensure
      WebMock.disable_net_connect!
    end
  }
end
