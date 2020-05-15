# frozen_string_literal: true

module Shortenator
  class Configuration
    attr_accessor :domains, :bitly_token, :remove_protocol, :ignore_200_check

    def initialize
      @domains = nil
      @bitly_token = nil
      @remove_protocol = false
      @ignore_200_check = false
    end
  end
end
