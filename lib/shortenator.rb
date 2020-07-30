# frozen_string_literal: true

require 'shortenator/version'
require 'shortenator/configuration'
require 'helpers/cachable'
require 'helpers/link_helpers'
require 'bitly'
require 'net/http'
require 'logger'

module Shortenator
  include Cachable
  include LinkHelpers
  class Error < StandardError; end

  # link_regex = /(http|ftp|https)://([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?/;
  # Your code goes here...
  class << self
    attr_accessor :config

    def config
      @config ||= Configuration.new
    end

    def reset
      @config = Configuration.new
    end

    def configure
      yield(config)
    end

    def search_and_shorten_links(
      text,
      domains = config.domains,
      ignore_200_check: config.ignore_200_check,
      tags: config.default_tags,
      additional_tags: [],
      bitly_group_guid: config.bitly_group_guid
    )
      all_tags = tags + additional_tags
      validate_config

      client = bitly_client
      text.split(' ').map do |word|
        shortenable_link?(word, domains, ignore_200_check) ? shorten_link(word, client, bitly_group_guid: bitly_group_guid, tags: all_tags) : word
      end.join(' ')
    end

    def bitly_client(token: config.bitly_token)
      Bitly::API::Client.new(token: token)
    end

    private

    def validate_config
      unless Integer === config.retry_amount && config.retry_amount >= 0
        raise Error, "retry amount must be a number equal or greater than 0, saw #{config.retry_amount}"
      end

      unless caching_model.nil?
        validate_caching_model
      end
    end

    def shortenable_link?(link, domains, ignore_200_check)
      domains.each do |domain|
        if link.include?(get_host_without_www(domain))
          return (ignore_200_check || valid_link?(link))
        end
      end
      false
    end

    def shorten_link(link, client, bitly_group_guid: nil, tags: [])
      retries = 0
      link = replace_localhost(link) if link.include? 'localhost'

      if cached_link?(link)
        caching_model.where(long_link: link).first.short_link
      else
        loop do
          begin
            bitly_response = client.create_bitlink(long_url: link, tags: tags, group_guid: bitly_group_guid)
            short_link = bitly_response.link
            caching_model&.create(long_link: link, short_link: short_link)

            short_link.slice! 'https://' if config.remove_protocol

            return short_link
          rescue Bitly::Error => e
            Logger.new(STDOUT).warn(e)
            retries += 1

            return link if retries >= config.retry_amount
          end
        end
      end
    end
  end
end
