# frozen_string_literal: true

module ShortenUrls
  class Configuration
    attr_accessor :domains
    attr_accessor :bitly_token
    attr_accessor :remove_protocol

    def initialize
      @domains = nil
      @bitly_token = nil
      @remove_protocol = false
    end
  end
end
