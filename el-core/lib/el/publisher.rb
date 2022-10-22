# frozen_string_literal: true

require_relative 'constants'
require_relative 'core_ext/blank'

module El
  # An object that registers events and subscribers and publishes those events to subscribers when they occur.
  class Publisher
    attr_reader :event_names

    # @param [Enumerable<Symbol>] event_names
    def initialize(event_names)
      @event_names = Set.new(event_names).freeze
      @subscriptions = event_names.reduce({}) do |h, name|
        h.merge!(name => [])
      end
    end

    class InvalidEvent < RuntimeError; end

    class Event
      attr_reader :name, :data

      # @param [Symbol] name
      # @param [Hash] data
      def initialize(name, data)
        @name = name
        @data = data
        freeze
      end

      def to_h
        { tag: self.class.name, event_name: name, event_data: data }
      end

      def to_json(*args)
        to_h.to_json(*args)
      end
    end

    private

    attr_reader :subscriptions

    def validate_event!(event_name)
      raise InvalidEvent, "#{event_name.inspect} is not a registered event" unless event_names.include?(event_name)

      self
    end

    # @param [Event, Symbol] event
    # @param [Hash] data
    #
    # @raise [InvalidEvent] if event is not an Event instance and it is not included in the events attribute
    #
    # @return [Event]
    def ensure_event(event, data)
      return event if event.is_a?(Event)

      validate_event!(event)

      Event.new(event, data)
    end

    public

    def subscriptions?(event_name: nil)
      return !subscriptions.empty? if event_name.nil?

      !subscriptions[event_name].blank?
    end

    def subscriber?(key)
      subscriptions.any? do |_, subscriptions|
        subscriptions.any? do |(k, _, _)|
          k == key
        end
      end
    end

    # @param [#call] subscriber
    # @param [Object] key
    # @param [Symbol] event_name
    #
    # @return [Publisher] this publisher
    def add_subscriber(subscriber, key: subscriber.object_id, event_name: :any, **meta_data)
      validate_event!(event_name)

      subscriptions[event_name] << [key, subscriber, meta_data]

      self
    end

    def <<(subscriber)
      add_subscriber(subscriber)
    end

    # @param [Object] key
    #
    # @return [Publisher] this publisher
    def remove_subscriber(key)
      subscriptions.each_pair do |(_name, subscriptions)|
        subscriptions.delete_if { |(k, _, _)| k == key }
      end

      self
    end

    # Publish the event to all subscribers.
    #
    # @param [Event, Symbol] event_or_name
    # @param [Hash] data
    #
    # @return [Event]
    def publish_event(event_or_name, data = EMPTY_HASH)
      return unless subscriptions?

      event = ensure_event(event_or_name, data.merge(published_at: Time.now).freeze)
      subs  = subscriptions[event.name]
      return if subs.blank?

      subs.each do |(_, subscriber, _)|
        subscriber.call(event)
      end

      event
    end
  end
end
