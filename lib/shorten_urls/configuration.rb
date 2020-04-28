# frozen_string_literal: true

module ShortenUrls
  class Configuration
    attr_accessor :domains
    attr_accessor :bitly_token

    def initialize
      @domains = nil
      @bitly_token = nil
    end
  end
end
