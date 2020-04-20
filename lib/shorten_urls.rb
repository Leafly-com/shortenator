# frozen_string_literal: true

require 'shorten_urls/version'
require 'shorten_urls/configuration'
require 'net/http'

module ShortenUrls
  class Error < StandardError; end

  # link_regex = /(http|ftp|https)://([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:/~+#-]*[\w@?^=%&/~+#-])?/;
  # Your code goes here...
  class << self
    attr_accessor :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def reset
      @configuration = Configuration.new
    end

    def configure
      yield(configuration)
    end

    def shorten_url(
      text,
      domains = @configuration.domains
    )
      text.split(' ').map do |word|
        shortenable_link?(word, domains) ? shorten_link(word) : word
      end.join(' ')
    end

    def shortenable_link?(link, domains)
      domains.each do |domain|
        return valid_link?(link) if link.include?(get_host_without_www(domain))
      end
      false
    end

    def valid_link?(link)
      uri = URI link
      response = Net::HTTP.get_response(uri)

      response.code.to_i == 200 || response.code.to_i == 301
    end

    def shorten_link(link)
      'short_link'
    end

    def get_host_without_www(url)
      url = "http://#{url}" if URI.parse(url).scheme.nil?
      host = URI.parse(url).host.downcase
      host.start_with?('www.') ? host[4..-1] : host
    end
  end
end
