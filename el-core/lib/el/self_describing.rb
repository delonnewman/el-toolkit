module El
  # Shared behavior for self-describing objects
  module SelfDescribing
    def classdoc(doc)
      classmeta(doc: doc)
    end
    alias moduledoc classdoc

    def classmeta(data)
      @metadata = data
    end
    alias modulemeta classmeta

    def metadata
      meta = @metadata || {}

      if @method_metadata
        meta.merge(methods: @method_metadata)
      else
        meta
      end
    end

    def doc(doc)
      meta(doc: doc)
    end

    def meta(data)
      @_metadata = data
    end

    def add_method_metadata(method, data)
      @method_metadata ||= {}
      @method_metadata[method] = data
    end

    def method_metadata(method = nil)
      return @method_metadata unless method

      @method_metadata[method]
    end

    def method_added(method)
      super

      add_method_metadata(method, @_metadata)

      @_metadata = nil
    end
  end
end
