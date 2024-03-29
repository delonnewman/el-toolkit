# frozen_string_literal: true

module El
  module SqlUtils
    module_function

    # Return a predicate hash with fully qualified identifiers
    #
    # @param predicates [Hash<Symbol, Object>]
    # @param table_name [Symbol]
    #
    # @return [Hash<Sequel::SQL::QualifiedIdentifier, Object>]
    def preprocess_predicates(predicates, table_name)
      predicates.transform_keys do |key|
        if key.is_a?(Sequel::SQL::QualifiedIdentifier)
          key
        else
          Sequel[table_name][key]
        end
      end
    end

    # @return [Array<{ fields: Array<Sequel::SQL::QualifiedIdentifier> table: Sequel::SQL::QualifiedIdentifier, ref: Sequel::SQL::QualifiedIdentifier }>]
    def all_component_attribute_query_info(entity_class, prefix = nil)
      entity_class.component_attributes.flat_map do |attr|
        results = component_attribute_query_info(entity_class, attr, prefix)

        if attr.value_class.component_attributes.empty?
          [results]
        else
          [results] + all_component_attribute_query_info(attr.value_class, attribute_name(attr, prefix))
        end
      end
    end

    def attribute_name(attr, prefix)
      prefix ? :"#{prefix}[#{attr.name}]" : attr.name
    end

    def component_attribute_query_info(entity_class, attr, prefix = nil)
      table     = Modeling::Utils.component_table_name(attr).to_sym
      attr_name = attribute_name(attr, prefix)
      ref_scope = prefix || Modeling::Utils.table_name(entity_class.name).to_sym

      { table:  Sequel[table].as(attr_name),
        ref:    Sequel[ref_scope][Modeling::Utils.reference_key(attr.name)],
        fields: attr.value_class.attributes
                    .reject { |a| a.exclude_for_storage? || a.component? }
                    .map { |a| Sequel[attr_name][a.name].as(:"#{attr_name}[#{a.name}]") } }
    end

    def run(query, *args, tag: nil, &block)
      tag = tag.nil? ? 'SQL' : "SQL #{tag}"
      app = Mentoring.app

      app.logger.info "#{tag}: #{query.gsub(/\s+/, " ")}, args: #{args.inspect}"

      results = []

      db = app.db
      db.fetch(query, *args) do |row|
        row = row.transform_keys(&:to_sym)
        results << row
      end

      return Core::EMPTY_ARRAY if results.empty?

      block ? block.call(results) : results
    end

    # TODO: for performance this would be better as opt-in
    def process_record(entity_class, hash_record)
      h = hash_record.dup

      attrs = entity_class.attributes

      attrs.select(&:serialize?).each do |attr|
        h.merge!(attr.name => YAML.dump(h[attr.name])) if h[attr.name]
      end

      comps = attrs.select(&:component?)

      comps.each do |attr|
        id_key = attr.reference_key.to_sym

        if !h.key?(id_key) && (id_val = h[attr.name].id)
          h[id_key] = id_val
        elsif !h.key?(id_key) && attr.required?
          raise "#{id_key.inspect} is required for storage but is missing: #{record.inspect}:#{entity_class}"
        end

        h.delete(attr.name)
      end

      h[:updated_at] = Time.now if h.key?(:updated_at)

      h
    end

    # TODO: Make this into a YAMLSerializer callable class
    def reconstitute_record(entity_class, hash)
      entity_class.attributes.select(&:serialize?).each_with_object(hash.dup) do |attr, h|
        h.merge!(attr.name => YAML.load(h[attr.name])) if h[attr.name]
      end
    end

    def build_entity(entity_class, record)
      record = DataUtils.parse_nested_hash_keys(reconstitute_record(entity_class, record))
      entity_class.new(record)
    end

    def ident_quote(db, *args)
      case args.size
      when 1
        db.literal(Sequel.identifier(args[0]))
      when 2
        db.literal(Sequel.qualify(*args))
      else
        raise ArgumentError, "wrong number or arguments (given #{args.size}, expected 1 or 2)"
      end
    end

    ATTRIBUTE_MAP = Hash.new { |_, key| key }

    def query_attribute_map(entity_class)
      entity_class.attributes.each_with_object(ATTRIBUTE_MAP.dup) do |attr, hash|
        attr_name = attr.component? ? entity_class.attribute_reference_key(attr) : attr.name
        if attr.many?
          hash
        else
          hash.merge!(attr.name => Sequel.qualify(entity_class.repository_table_name, attr_name))
        end
      end
    end

    def query_fields(entity_class, db)
      fields =
        query_attribute_map(entity_class)
          .reject { |(name, _)| entity_class.exclude_for_storage.include?(name) }
          .map { |(_, ident)| db.literal(ident) }

      entity_class.component_attributes.each_with_index do |comp, i|
        comp.value_class.storable_attributes.each do |attr|
          table = "#{entity_class.component_table_name(comp)}#{i}"
          ident = Sequel.qualify(table, attr.name)
          name = Sequel.identifier("#{comp.name}_#{attr.name}")
          fields << "#{db.literal(ident)} as #{db.literal(name)}"
        end
      end

      fields.join(', ')
    end

    def query_template(entity_class, db, one:, predicates:, order_by: nil)
      buffer = StringIO.new

      buffer.write 'select '
      buffer.write query_fields(entity_class, db)
      buffer.write ' from '
      buffer.write entity_class.repository_table_name

      entity_class.component_attributes.each_with_index do |attr, i|
        component_table_name = entity_class.component_table_name(attr)
        component_table_alias = "#{component_table_name}#{i}"
        buffer.write " inner join #{ident_quote(db, component_table_name)}"
        buffer.write " as #{ident_quote(db, component_table_alias)}"
        buffer.write ' on '
        buffer.write ident_quote(db, entity_class.repository_table_name, entity_class.attribute_reference_key(attr))
        buffer.write ' = '
        buffer.write ident_quote(db, component_table_alias, 'id')
      end

      buffer.write(' /* where */') if predicates
      buffer.write(" order by #{ident_quote(db, order_by)}") if one == false && order_by
      buffer.write(' limit 1') if one

      buffer.string
    end

    def where(db, predicates)
      preds = predicates.map { |(ident, _)| "#{db.literal(ident)} = ?" }

      ["where #{preds.join(" and ")}", predicates.values]
    end
  end
end
