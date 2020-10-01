require 'json'
require 'stringio'
require 'set'
require 'erb'
require 'forwardable'
require 'active_model'

require_relative 'html'

module El
  module HTML
    module Utils
      def render_content(content)
        content.map { |elem| render_element(elem) }.join('')
      end

      def render_element(elem)
        if elem.respond_to?(:to_html)
          elem.to_html
        else
          elem.to_s
        end
      end
    end

    class Tag
      include HTML::Utils

      attr_reader :name, :attributes, :content

      def initialize(name, attributes = {}, *content)
        @name       = name
        @attributes = attributes
        @content    = content
      end

      def to_html
        if attributes.empty?
          "<#{name}>#{render_content(content)}</#{name}>"
        else
          "<#{name} #{render_attributes}>#{render_content(content)}</#{name}>"
        end
      end

      def +(value)
        case value
        when Array
          l = TagList[*value]
          l.unshift(self)
        else
          TagList[self, value]
        end
      end

      private

      def render_attributes
        attributes.reduce([]) do |attrs, (name, value)|
          if value == true
            attrs << name.to_s
          elsif value == false || value.nil?
            attrs
          else
            attrs << "#{name}=\"#{value}\""
          end
        end.join(' ')
      end
    end

    class TagList < Array
      include HTML::Utils

      def to_html
        render_content(self)
      end

      alias orig_concat +
      def +(value)
        case value
        when Array
          TagList[*self.orig_concat(value)]
        else
          l = TagList[*self]
          l << value
        end
      end
    end
  end

  # TODO: Add `document` and `jQuery` methods that return objects that mimick there API's and generate the appropriate code.
  module JavaScript
    def select(pattern)
      Query.new(pattern)
    end

    def alert(msg)
      Alert.new(msg)
    end

    module Utils
      # TODO: add more data types to serialize
      def to_javascript(value)
        if value.respond_to?(:to_js)
          value.to_js
        else
          case value
          when Date, Time, DateTime
            "new Date(#{value.to_time.to_i})"
          else
            value.to_json
          end
        end
      end
    end

    class Program
      def initialize(statements = [])
        @statements = statements
      end

      def <<(statement)
        @statements << statement
      end

      def to_js
        @statements.map(&:to_js).join(";\n") + ";\n"
      end
    end

    class Base
      include JavaScript
    end

    class Alert
      include Utils

      attr_reader :message

      def initialize(msg)
        @message = msg
      end

      def to_js
        "alert(#{to_javascript(message)})"
      end
    end
  
    class Query < Base
      attr_reader :pattern
  
      def initialize(pattern)
        @pattern = pattern
      end
  
      def inner_text!(text)
        SetQueryInnerText.new(self, text)
      end
  
      def inner_text
        GetQueryInnerText.new(self)
      end
  
      def select(pattern)
        Finder.new(self, pattern)
      end
  
      def to_js
        "document.querySelectorAll(#{pattern.to_json})"
      end
    end
  
    class Finder < Query
      attr_reader :query, :pattern
  
      def initialize(query, pattern)
        @query = query
        @pattern = pattern
      end
  
      def to_js
        "#{query.to_js}.find(#{pattern.to_json}"
      end
    end
  
    class SetQueryInnerText
      attr_reader :query, :text
  
      def initialize(query, text)
        @query = query
        @text  = text
      end
  
      def to_js
        "#{query.to_js}.forEach(function(e) { e.innerText = #{text.to_json} })"
      end
    end
  
    class GetQueryInnerText
      attr_reader :query
  
      def initialize(query)
        @query = query
      end
  
      def to_js
        "#{query.to_js}.text()"
      end
    end
  end

  module Rendering
    def io
      @io ||= StringIO.new
    end

    def render(component, *args)
      instance = component.new(*args)
      io.puts instance.to_html
#      unless component.events.empty?
#        io.puts "<script>"
#        component.events.each do |event|
#          io.puts render_event(instance, event)
#        end
#        io.puts "</script>"
#      end
      io.string
    end
    
    def render_event(component, event)
      css_class = ".#{component.class.to_s.downcase}"
      "document.querySelectorAll(#{css_class.to_json}).forEach(function(e) { e.addEventListener(#{event.to_s.to_json}, function() { #{component.send(event).to_js} }, false); });"
    end
  end

  class Component
    include HTML
    include JavaScript
    include ActiveModel::Model
    include ActiveModel::Attributes
    include Rendering

    extend ActiveModel::Callbacks

    define_model_callbacks :initialize

    attribute :content
    attribute :tag_name, default: 'div'

    class << self
      def renderer
        @renderer
      end

      def content(&blk)
        @renderer = blk
      end

      def tag_name(tag)
        attribute :tag_name, default: tag
      end

      def event_names
        @events_names ||= []
      end

      def custom_events
        @custom_events || {}
      end

      def events(mapping)
        @custom_events =
          case mapping
          when Array
            mapping.map { |x| [x, x] }.to_h
          else
            mapping
          end
      end

      # TODO: add ActiveModel-like, callbacks for events
      def on(name, &blk)
        event_names << name
        define_method name, &blk
      end

      def classes(names)
        attribute :classes, default: names
      end
    end

    delegate :inner_text, :inner_text!, to: :select_self

    attr_reader :html, :javascript

    def initialize(*args)
      run_callbacks :initialize do
        if args.length == 0
          super()
        elsif args.length == 1
          case args[0]
          when Hash
            super(args[0])
          else
            super(content: args[0])
          end
        elsif args.length == 2
          super(args[1].merge(content: args[0]))
        else
          raise ArgumentError, "wrong number of arguments (given #{args.length}, expected 1 or 2)"
        end
        if self.class.renderer
          instance_eval(&self.class.renderer)
          self.content = io.string
        end
      end
    end

    def to_html
      "<#{tag_name} id=\"#{html_id}\" class=\"#{html_class}\" #{events_html}>#{content}</#{tag_name}>"
    end

    def +(value)
      case value
      when Array
        l = HTML::TagList[*value]
        l.unshift(self)
      else
        HTML::TagList[self, value]
      end
    end

    def events
      self.class.event_names.reduce({}) do |h, event|
        h.merge!(event => send(event))
      end
    end

    def events_html
      es = events
      return '' if es.empty?
      events.map { |(event, js)| "on#{event}='#{js.to_js}'" }.join(' ')
    end

    def html_ident
      self.class.to_s.underscore.dasherize.tr('/', '.')
    end

    def html_class
      if respond_to?(:classes)
        classes.join(' ')
      else
        html_ident
      end
    end

    def html_class_selector
      if respond_to?(:classes)
        ".#{classes.first}"
      else
        ".#{css_class}"
      end
    end

    def html_id
      if respond_to?(:classes)
        "#{html_ident}-#{object_id}"
      else
        "#{html_class}-#{object_id}"
      end
    end

    def html_id_selector
      "##{html_id}"
    end

    def select(pattern)
      JavaScript::Query.new(pattern)
    end

    def select_self
      select(html_id_selector)
    end

    def javascript
      js = JavaScript::Program.new
      yield(js)
      js
    end
  end
end

class Greeter < El::Component
  content do
    'Hi!'
  end

  on :click do
    javascript do |js|
      js << inner_text!('Hello')
      js << alert('Hey There')
    end
  end
end

module Bootstrap4
  class Alert < El::Component
    classes %w(alert alert-primary)

    attribute :role, default: 'alert'
    attribute :dismissible, :boolean, default: true

    events close: 'close.bs.alert',
           closed: 'closed.bs.alert'

    after_initialize do
      if dismissible?
        self.classes += %w(alert-dismissible fade show)
        self.content += dismiss_button
      end
    end

    def dismissible?
      dismissible
    end

    def dismiss_button
      tag.button(type: 'button', class: 'close', data_dismiss: 'alert', aria_label: 'Close') do
        tag.span(aria_hidden: 'true') { '&times'.html_safe }
      end
    end

    def style=(style)
      self.classes = %W(alert alert-#{style})
    end
  end
end

B = Bootstrap4

class Home < El::Component
  content do
    B::Alert.new("Hello Everyone!", style: :warning)
  end

  on :click do
    alert(Date.new)
  end
end


Test = Class.new do
  include El::Rendering

  def html
    ERB.new(IO.read('./template.erb')).result(binding)
  end
end

puts Test.new.html
