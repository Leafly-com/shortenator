# frozen_string_literal: true

module Shortenator
  class Configuration
    attr_accessor \
      :bitly_group_guid
      :bitly_token, 
      :default_tags, 
      :domains, 
      :ignore_200_check, 
      :localhost_replacement, 
      :remove_protocol, 
      :retry_amount, 

    def initialize
      @bitly_group_guid = nil
      @bitly_token = nil
      @default_tags = []
      @domains = nil
      @ignore_200_check = false
      @localhost_replacement = 'example.com'
      @remove_protocol = false
      @retry_amount = 3
    end
  end
end
