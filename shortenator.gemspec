# frozen_string_literal: true

require_relative 'lib/shortenator/version'

Gem::Specification.new do |spec|
  spec.name          = 'shortenator'
  spec.version       = Shortenator::VERSION
  spec.authors       = ['Philippe Batigne']
  spec.email         = ['philippe.batigne@leafly.com']

  spec.summary       = 'To find and shorten links in text!'
  spec.homepage      = 'https://leafly.com/'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata['allowed_push_host'] = "http://leafly.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'http://github.com/leafly/shortenator.git'
  spec.metadata['changelog_uri'] = 'http://github.com/leafly/shortenator/blob/master/README.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'bitly'
end
