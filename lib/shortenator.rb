# frozen_string_literal: true

require 'shortenator/version'
require 'shortenator/configuration'
require 'bitly'
require 'net/http'
require 'logger'

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

    def caching_model
      config.caching_model
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
      if(!caching_model.nil?)
        if !caching_model_is_correct_fields?
          raise Error, "Model is not valid, it must be an object (perferably ActiveRecord) with a `long_link` and `short_link`"
        end
        if !caching_model_is_correct_methods?
          raise Error, "Model is not valid, it must be an object (perferably ActiveRecord) with `find_by(long_link:)` and `create(long_link:, short_link:)` methods"
        end
      end
    end

    def caching_model_is_correct_fields?
      attrs_to_find = [
        :long_link,
        :long_link=,
        :short_link,
        :short_link=
      ]
      
      caching_model.instance_methods(false).any? { |attr| attrs_to_find.include?(attr) }
    end

    def caching_model_is_correct_methods?
      methods_to_find = [
        :find_by,
        :create
      ]
      
      caching_model.singleton_class.instance_methods.any? { |method| methods_to_find.include?(method) }
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

    def shorten_link(link, client, bitly_group_guid: nil, tags: [])
      retries = 0
      link = replace_localhost(link) if link.include? 'localhost'
      
      if(has_cached_link(link))
        return caching_model.find_by(long_link: link).first.short_link
      else 
        loop do
          begin
            bitly_response = client.create_bitlink(long_url: link, tags: tags, group_guid: bitly_group_guid)
            short_link = bitly_response.link
            caching_model.create(long_link: link, short_link: short_link) unless caching_model.nil?

            short_link.slice! 'https://' if config.remove_protocol

            return short_link
          rescue Bitly::Error => e
            retries += 1
            
            return link if retries >= config.retry_amount
          end
        end
      end
    end

    def has_cached_link(link)
      return false if caching_model.nil?
      results = caching_model.find_by(long_link: link)
      case results.size
      when 0
        false
      when 1
        true
      else
        Logger.new(STDOUT).info { "found more than one shortened link, will be using first one" }
        true
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
