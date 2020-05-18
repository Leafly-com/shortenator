# frozen_string_literal: true

require 'shortenator/version'
require 'shortenator/configuration'
require 'bitly'
require 'net/http'

module Shortenator
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
      ignore_200_check: config.ignore_200_check
    )
      validate_config

      client = Bitly::API::Client.new(token: config.bitly_token)
      text.split(' ').map do |word|
        shortenable_link?(word, domains, ignore_200_check) ? shorten_link(word, client) : word
      end.join(' ')
    end

    private

    def validate_config
      unless Integer === config.retry_amount && config.retry_amount >= 0
        raise Error, "retry amount must be a number equal or greater than 0, saw #{config.retry_amount}"
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

    def valid_link?(link)
      response = Net::HTTP.get_response(URI.parse(link))
      if response.code == '301' || response.code == '302'
        response = Net::HTTP.get_response(URI.parse(response.header['location']))
      end
      response.code.to_i == 200
    end

    def shorten_link(link, client)
      retries = 0
      link = replace_localhost(link) if link.include? 'localhost'
      loop do
        begin
          bitly_response = client.shorten(long_url: link)
          short_link = bitly_response.link
          short_link.slice! 'https://' if config.remove_protocol

          return short_link
        rescue Bitly::Error => e
          retries += 1

          return link if retries >= config.retry_amount
        end
      end
    end

    def replace_localhost(link)
      link.gsub(/localhost:[0-9]+/, config.localhost_replacement)
    end

    def get_host_without_www(url)
      url = "http://#{url}" if URI.parse(url).scheme.nil?
      host = URI.parse(url).host.downcase
      host.start_with?('www.') ? host[4..-1] : host
    end
  end
end
