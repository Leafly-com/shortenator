# frozen_string_literal: true

module ShortenUrls
  class Configuration
    attr_accessor :domains

    def initialize
      @domains = nil
    end
  end
end
