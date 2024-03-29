module El
  class Entity::Dereferencer
    attr_reader :entity_class

    def initialize(entity_class)
      @entity_class = entity_class
    end

    def call(entity_data)
      entity_data.each_with_object({}) do |(name, value), data|
        unless entity_class.attribute?(name)
          data[name] = value
          next
        end

        attr = entity_class.attribute(name)

        data[name] =
          if attr.deref? && attr.entity?
            attr.value_class[value]
          else
            value
          end
      end
    end
  end
end
