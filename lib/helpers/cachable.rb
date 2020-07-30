# frozen_string_literal: true

require 'logger'

module Cachable
  class AttributesError < StandardError
    class << self
      def base_message
        'Model is not valid, it must be an object (perferably ActiveRecord)'
      end
    end
  end

  module ClassMethods
    def caching_model
      config.caching_model
    end

    def validate_caching_model
      errors = []
      errors << 'a `long_link` and `short_link`' unless caching_model_is_correct_fields?
      errors << '`find_by(long_link:)` and `create(long_link:, short_link:)` methods' unless caching_model_is_correct_methods?

      raise AttributesError, "#{AttributesError.base_message} with #{errors.join('; ')}" unless errors.empty?
    end

    def caching_model_is_correct_fields?
      attrs_to_find = %i[
        long_link
        short_link
      ]

      caching_model.new.methods.any? { |method| attrs_to_find.include?(method) }
    end

    def caching_model_is_correct_methods?
      methods_to_find = %i[
        find_by
        create
      ]

      caching_model.singleton_class.instance_methods.any? { |method| methods_to_find.include?(method) }
    end

    def cached_link?(link)
      return false if caching_model.nil?

      results = caching_model.find_by(long_link: link)
      case results.size
      when 0
        false
      when 1
        true
      else
        Logger.new(STDOUT).info { 'found more than one shortened link, will be using first one' }
        true
      end
    end
  end

  extend ClassMethods

  def self.included(other)
    other.extend(ClassMethods)
  end
end
