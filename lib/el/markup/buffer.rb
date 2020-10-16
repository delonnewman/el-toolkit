module El
  class Markup
    class Buffer
      def initialize(markup)
        @markup = markup
        @buffer = StringIO.new
      end

      def method_missing(*args, &block)
        elem = block ? @markup.send(*args, &block) : @markup.send(*args)

        @buffer.puts Utils.to_markup(elem)

        elem
      end

      def respond_to?(method, include_all = false)
        @markup.respond_to?(method, include_all)
      end

      def text(*args)
        args.each do |arg|
          @buffer.write arg.to_s
        end
        @buffer.write("\n")

        self
      end

      def to_markup
        @buffer.string
      end
      alias to_s to_markup
    end
  end
end