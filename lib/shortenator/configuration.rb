# frozen_string_literal: true

module Shortenator
  class Configuration
    attr_accessor :domains, :bitly_token, :remove_protocol, :ignore_200_check, :retry_amount, :localhost_replacement, :tags, :group_guid

    def initialize
      @domains = nil
      @bitly_token = nil
      @remove_protocol = false
      @ignore_200_check = false
      @retry_amount = 3
      @localhost_replacement = 'example.com'
      @tags = []
      @group_guid = nil
    end
  end
end
