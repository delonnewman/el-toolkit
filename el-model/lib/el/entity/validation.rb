require 'el/core_ext/blank'

module El
  class Entity
    module Validation
      def valid?(entity)
        return false if entity.empty?

        attributes.reduce(true) do |is_valid, attr|
          is_valid && attr.required? && !!(value = entity[attr.name]) &&
            attr.valid_value?(value) && !attr.default
        end
      end

      # TODO: move this to a validator or form object similar in function to repository
      def errors(entity)
        attributes.reduce({}) do |errors, attr|
          key = attr.name
          name = key.to_s.tr('_', ' ').capitalize

          a = []

          if attr.required? && (value = entity[key]).blank? && !attr.default
            a << attr.fetch(:message) { "#{name} is required" }
          end

          if value && !attr.valid_value?(value)
            a << attr.fetch(:message) { "#{name} is not valid" }
          end

          unique = attr[:unique]

          repo =
            if unique.is_a?(Class) && unique < Entity
              unique.repository
            elsif unique.is_a?(Repository)
              unique
            else
              repository
            end

          if unique && repo.find_by(attr.name => value)
            a << attr.fetch(:message) { "#{name} is not unique" }
          end

          a.empty? ? errors : errors.merge!(key => a)
        end
      end
    end
  end
end
