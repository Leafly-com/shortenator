# frozen_string_literal: true

require 'shorten_urls/version'
require 'shorten_urls/configuration'
require 'bitly'
require 'net/http'

module ShortenUrls
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

    def shorten_url(
      text,
      domains = config.domains
    )
      client = Bitly::API::Client.new(token: config.bitly_token)
      text.split(' ').map do |word|
        shortenable_link?(word, domains) ? shorten_link(word, client) : word
      end.join(' ')
    end

    def shortenable_link?(link, domains)
      domains.each do |domain|
        return valid_link?(link) if link.include?(get_host_without_www(domain))
      end
      false
    end

    def valid_link?(link)
      response = Net::HTTP.get_response(URI.parse(link))
      if response.code == '301'
        response = Net::HTTP.get_response(URI.parse(response.header['location']))
      end

      response.code.to_i == 200
    end

    def shorten_link(link, client)
      short_link = client.shorten(long_url: link).link
      short_link.slice! 'https://' if config.remove_protocol

      short_link
    end

    def get_host_without_www(url)
      url = "http://#{url}" if URI.parse(url).scheme.nil?
      host = URI.parse(url).host.downcase
      host.start_with?('www.') ? host[4..-1] : host
    end
  end
end
