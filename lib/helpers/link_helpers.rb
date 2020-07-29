require 'logger'

module LinkHelpers
  module ClassMethods
    def valid_link?(link)
      response = Net::HTTP.get_response(URI.parse(link))
      if response.code == '301' || response.code == '302'
        response = Net::HTTP.get_response(URI.parse(response.header['location']))
      end
      response.code.to_i == 200
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
  extend ClassMethods

  def self.included( other )
    other.extend( ClassMethods )
  end
end