module El
  module Entity::Repositories
    def repository_class_name(class_name = nil)
      @repository_class_name = class_name if class_name
      @repository_class_name || "#{self}Repository"
    end

    def repository_class(klass = nil)
      @repository_class = klass if klass
      return @repository_class if @repository_class

      class_name = repository_class_name
      @repository_class = const_get(class_name) if const_defined?(
        class_name
      )
      @repository_class || Repository
    end

    def repository_table_name
      Utils.table_name(name)
    end

    # When no arguments are given it will return a repository instance. When the class argument
    # is given the value will be used to generate repository instances. When the class_name argument
    # is given the value will be used to fetch the named class as a constant.
    #
    # @example
    #   Product.repository # returns an anonymous repository instance
    #
    # @example
    #   class Product < Entity
    #     repository do
    #       def random
    #         to_a.sample
    #       end
    #     end
    #   end
    #
    #   Product.repository # returns an instance of an anonymous repository subclass with the defined methods
    #
    # @example
    #   class ProductRepository < Repository
    #     def random
    #       to_a.sample
    #     end
    #   end
    #
    #   class Product < Entity
    #   end
    #
    #   Product.repository # returns an instance of ProductRepository
    #
    # @example
    #   class ProductRepo < Repository
    #     def random
    #       to_a.sample
    #     end
    #   end
    #
    #   class Product < Entity
    #     repository class: ProductRepo
    #   end
    #
    #   Product.repository # returns an instance of ProductRepo
    #
    # @example
    #   class Product < Entity
    #     repository class_name: 'ProductRepo'
    #   end
    #
    #   Product.repository # returns and instance of ProductRepo
    #
    # @param options [Hash]
    # @option class_name [String] the name of a user defined subclass of Repository
    # @option class [Class] a user defined subclass of Repository
    # @param block [Proc] a class body for an anonymous Repository subclass
    #
    # @return [Repository]
    def repository(**options, &block)
      if (klass = options[:class])
        repository_class(klass)
      elsif (class_name = options[:class_name])
        repository_class_name(class_name)
      elsif block
        repository_class Class.new(Repository)
        repository_class.class_eval(&block)
      end
    end
  end
end
