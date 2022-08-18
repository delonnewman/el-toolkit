module El
  class ChangeSet::Change
    CHANGES = Set[:add, :remove].freeze

    attr_reader :change, :attribute, :options

    def initialize(change, attribute, value, options)
      raise "invalid change `#{change}`" unless CHANGES.include?(change)

      @change    = change
      @attribute = attribute
      @value     = value
      @options   = options
    end
  end

  # @param entity_data [Hash]
  #
  # @return [Hash]
  def apply!(entity_data)
    case change
    when :remove
      entity_data.delete(attribute)
    else
      entity_data[attribute] = value
    end
    entity_data
  end

  # @param entity_data [Hash]
  #
  # @return [Hash]
  def apply(entity_data)
    apply!(entity_data.dup)
  end
end