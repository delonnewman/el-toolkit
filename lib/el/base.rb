module El
  class Base
    class << self
      def abstract!
        @abstract = true
        #class_eval("def self.new(*_); raise 'Abstract classes cannot be initialized' end")
      end

      def abstract?
        @abstract == true
      end

      def file=(value)
        @file = value
      end

      def file
        @file
      end

      def source
        @source ||= IO.read(file) if file
      end
    end

    abstract!
  end
end