module El
  # Designed to work with Publisher provides a default call implementation so subscribers
  # can be defined with a more intuitive "update" method like Ruby's Observable module.
  #
  # @example
  #   class View < Subscriber
  #     attr_accessor :say
  #
  #     def initialize
  #       self.say = "Hola"
  #     end
  #
  #     def update(event)
  #       self.say = event.data.fetch(:say, self.say)
  #     end
  #   end
  #
  #   publisher = El::Publisher.new([:create, :update])
  #   publisher.register_subscriber(View)
  #   publisher.publish_event(:create, { say: "Hi" })
  #
  # @see Publisher
  class Subscriber
    def call(event)
      update(event)
    end
  end
end
