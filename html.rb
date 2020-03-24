require 'cgi'

module El
  module HTML
    # tag(:a, {class: 'btn btn-primary', href: "#"}, "Test")
    # tag('a.btn.btn-primary', {href: "#"}, "Test")
    # tag(:b, "Hey!")
    # tag(:br)
    # tag.b("Hey!")
    # tag.br
    # tag.button(type: 'button') { "Click Me!" }
    # tag.a.btn.btn-primary(href: "#") { "Test" }
    # tag.a.btn.btn-primary({href: "#"}, "Test")
    def tag(*args)
      case args.length
      when 0
        Builder.new
      else
        args << yield if block_given?
        evaluate(args)
      end
    end
  
    class Bus < BasicObject
      def self.const_missing(name)
        ::Object.const_get(name)
      end
  
      def method_missing(tag, *args)
        builder = Builder.new
        if Kernel.send(:block_given?)
          builder.send(tag, *args, &Proc.new)
        else
          builder.send(tag, *args)
        end
      end
  
      def pretty_print
        "#<El::Bus:0x#{__id__.to_s(16)}>"
      end
      alias inspect pretty_print
    end
  
    class Sequence < Array
      def to_s
        join('')
      end
  
      def inspect
        to_s.inspect
      end
      alias pretty_print inspect
    end
  
    class Builder
      include El::HTML
  
      def initialize(tag = nil, content = [], classes = [])
        @tag     = tag
        @content = content
        @classes = classes
      end
  
      def <<(other)
        if other.is_a?(Sequence)
          Sequence[self] + other
        else
          Sequence[self, other]
        end
      end
      alias + <<
  
      def *(n)
        buff = Sequence.new
        n.times do
          buff << Builder.new(@tag, @content, @classes)
        end
        buff
      end
  
      def method_missing(method, *args)
        if @tag
          add_class(method)
        else
          @tag = method
        end
  
        if args.length == 1 and args[0].is_a?(Hash)
          update_attrs(args[0])
        elsif !args.empty?
          if args[0].is_a?(Hash)
            update_attrs(args[0])
            args.slice!(0)
          end
          args.each do |arg|
            @content << arg
          end
        end
  
        res = Bus.new.instance_eval(&Proc.new) if block_given?
        @content << res unless res.nil?
  
        self
      end
  
      def attrs
        if @attrs
          classes = if @attrs[:class]
                      @classes << @attrs[:class]
                    else
                      @classes
                    end
          if classes.empty?
            @attrs
          else
            @attrs.merge(class: classes.join(' '))
          end
        elsif @classes
          { class: @classes.join(' ') }
        end
      end
  
      def to_a
        attrs_ = attrs
        tag = [@tag]
        tag << attrs_ unless attrs_.nil?
        @content.each do |item|
          tag << if item.is_a?(Builder)
                   item.to_a
                 else
                   item
                 end
        end
        tag
      end
  
      def to_s
        evaluate(to_a)
      end
      alias to_str to_s
  
      def inspect
        to_s.inspect
      end
      alias pretty_print inspect
  
      private
  
        def update_attrs(attrs)
          if @attrs.nil?
            @attrs = attrs
          else
            @attrs.merge!(attrs)
          end
        end
  
        def add_class(name)
          @classes << name.to_s.gsub('_', '-')
        end
    end
  
    class HTMLSafeString
      def initialize(string)
        @string = string
      end

      def to_s
        @string
      end
    end

    class ::String
      def html_safe
        HTMLSafeString.new(self)
      end
    end

    DEFINITIONS = {}
  
    EMPTY_TAGS = Set[
      :br,
      :img,
      :link,
      :meta,
      :base,
      :area,
      :col,
      :hr,
      :input,
      :param,
      :source,
      :track,
      :wbr,
      :keygen
    ].freeze
  
    def define(name, &block)
      DEFINITIONS[name] = block
    end
  
    def mixin(mod)
      mod.instance_methods(false).each do |method_name|
        DEFINITIONS[method_name] = mod.instance_method(method_name).bind(El::HTML)
      end
    end
  
    def evaluate(form)
      ret = case form
            when nil
              ''
            when HTMLSafeString
              form.to_s
            when String
              CGI.escape_html(form)
            when TrueClass
              'Yes'
            when FalseClass
              'No'
            when Numeric, Symbol, Builder
              form.to_s
            when Array
              case form[0]
              when Proc
                render_proc_array(form[0], form.drop(1))
              when Symbol, String
                render_tag(form)
              else
                render_form_list(form)
              end
            else
              raise "Unknown form: #{form.inspect}"
            end
  
      # Return an HTML Safe string if ActiveSupport is available
      if defined?(ActiveSupport)
        ActiveSupport::SafeBuffer.new(ret)
      else
        ret
      end
    end
  
    def expand1(form)
      name = form[0]
      macro = DEFINITIONS[name]
      exp1 = method(:expand1)
      if macro and has_attributes?(form)
        attrs = form[1]
        args = form.drop(2).map(&exp1)
        if args.empty?
          macro.call(nil, attrs)
        else
          macro.call(args, attrs)
        end
      elsif macro
        args = form.drop(1).map(&exp1)
        macro.call(args, {})
      else
        form
      end
    end
  
    def expand(form)
      case form
      when Array
        case form[0]
        when Symbol
          expand1(form)
        else
          form
        end
      else
        form
      end
    end
  
    private
  
      def has_attributes?(form)
        form[1].is_a?(Hash) and !form[1].empty?
      end
  
      def format_attr_name(name)
        buffer = []
        tokens = name.to_s.split('')
        tokens.each_with_index do |token, i|
          if token =~ /[A-Z]/
            buffer << '-' if i != 0
            buffer << token.downcase
          elsif token == '_'
            buffer << '-'
          else
            buffer << token
          end
        end
        buffer.join('')
      end
  
      def format_attr(name, value)
        # data: {entry_id: 4, method: 'delete'} => 'data-entry-id="4" data-method="delete"'
        if value.is_a?(Hash)
          value.map { |(k, v)| "#{format_attr_name(name)}-#{format_attr_name(k)}=\"#{v}\"" }.join(' ')
  
        # href: ['https://google.com', {q: 'Hello Everyone'}] => 'href="https://google.com?q=Hello%20Everyone"
        elsif name == :href or name == :src and value.is_a?(Array)
          if value.length == 2
            param_str = value[1].map { |(k, v)| "#{k}=#{URI.escape(v)}" }.join('&')
            "#{name}=\"#{value[0]}?#{param_str}\""
          else
            "#{name}=\"#{value[0]}\""
          end
  
        # class: ['btn', 'btn-secondary', 'btn-sm'] => 'class="btn btn-secondary btn-sm"'
        elsif value.is_a?(Array)
          "#{format_attr_name(name)}=\"#{value.join(' ')}\""
        elsif value == true
          format_attr_name(name)
        elsif value.nil? or value == false
          ''
        else
          "#{format_attr_name(name)}=\"#{value}\""
        end
      end
  
      def render_attributes(attrs)
        attrs.map { |(name, value)| format_attr(name, value) }.join(' ')
      end
  
      def parse_tag_name(name)
        tokens = name.to_s.split('')
        classes = []
        ids = []
        buffer = []
        read_class = false
        read_id = false
        name_ = nil
        tokens.each do |token|
          if token == '.'
  
          end
        end
      end
  
      def render_tag(form)
        form_ = expand1(form)
        name = form_[0]
        if EMPTY_TAGS.include?(name.to_sym) and form_[1].is_a?(Hash)
          "<#{name} #{render_attributes(form_[1])}>"
        elsif EMPTY_TAGS.include?(name.to_sym)
          "<#{name}>"
        elsif form_[1].is_a?(Hash)
          "<#{name} #{render_attributes(form_[1])}>#{render_form_list(form_.drop(2))}</#{name}>"
        else
          "<#{name}>#{render_form_list(form_.drop(1))}</#{name}>"
        end
      end
  
      def render_form_list(forms)
        forms.map(&method(:evaluate)).join('')
      end
  
      extend self
  end
end
