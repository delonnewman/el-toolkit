module El
  # Methods used for Entity associations
  module Entity::Associations
    def reference_key
      :"#{canonical_name.downcase}_id"
    end

    def has_many(name, **options)
      type = El::Modeling::Utils.entity_name(name)
      meta = { required: false }.merge!(options.merge(cardinality: :one_to_many, exclude_for_storage: true))
      define_attribute(name, type, **meta)
      name
    end

    def has_and_belongs_to_many(name, **options)
      type = El::Modeling::Utils.entity_name(name)
      meta = { required: false }.merge!(options.merge(cardinality: :many_to_many, exclude_for_storage: true))
      define_attribute(name, type, **meta)
      name
    end

    def belongs_to(name, **options)
      type = El::Modeling::Utils.entity_name("#{self}_#{name}", namespace: true)
      define_attribute(name, type, **options.merge(cardinality: :many_to_one, exclude_for_storage: true))

      attr = attribute(name)
      define_method name do
        attr.value_class[value_for(name)]
      end

      name
    end

    def has_one(name, **options)
      type = El::Modeling::Utils.entity_name(name)
      define_attribute(name, type, **options.merge(cardinality: :one_to_one, exclude_for_storage: true))
      name
    end

    def reference(name, type, **options)
      define_attribute(name, type, **options.merge(reference: true, unique: true, index: true))
    end
    alias define_reference reference

    def reference_mapping
      attributes.select(&:reference?).reduce({}) do |h, a|
        h.merge!(a.type_predicate => a.name)
      end
    end

    def primary_key(name = :id, type = :integer, **options)
      options = options.merge(required: false, primary_key: true)

      if type == :uuid
        options[:default] = -> { SecureRandom.uuid }
        options[:required] = true
      end

      define_reference(name, type, **options)
    end

    def storable_attributes
      attributes.reject(&:exclude_for_storage?)
    end

    def component_attributes
      attributes.select { |a| a.cardinality == :many_to_one }
    end

    def exclude_for_storage
      attributes.select(&:exclude_for_storage?).map(&:name)
    end
  end
end
