require 'logger'

module Cachable
  module ClassMethods
    def caching_model
      config.caching_model
    end

    def validate_caching_model
      if !caching_model_is_correct_fields?
        raise "Model is not valid, it must be an object (perferably ActiveRecord) with a `long_link` and `short_link`"
      end
      if !caching_model_is_correct_methods?
        raise "Model is not valid, it must be an object (perferably ActiveRecord) with `find_by(long_link:)` and `create(long_link:, short_link:)` methods"
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
  end

  extend ClassMethods

  def self.included( other )
    other.extend( ClassMethods )
  end
end