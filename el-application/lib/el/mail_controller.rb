# frozen_string_literal: true

require_relative 'templating'

module El
  # A controller for
  class MailController
    extend Forwardable
    include Templating

    def initialize(app)
      @app = app
    end

    def deliver!(message, *args)
      public_send(message, *args).wait!
    end

    protected

    attr_reader :app

    def_delegator :app, :logger

    DEFAULT_FROM = 'contact@delonnewman.name'
    private_constant :DEFAULT_FROM

    def mail(name, view = EMPTY_HASH, to:, subject:, from: DEFAULT_FROM)
      content = render_template(name, view)

      msg = [{
        'From'     => {
          'Email' => from,
          'Name'  => 'Delon R. Newman Mentoring Bot'
        },
        'To'       => [{ 'Email' => to.email, 'Name' => to.username }],
        'Subject'  => subject,
        'HTMLPart' => content
      }]

      logger.info "Sending message: #{msg.inspect}"

      Concurrent::Promises.future do
        Mailjet::Send.create(messages: msg).tap do |res|
          logger.info "Mailjet response: #{res.inspect}"
        end
      end
    end
  end
end
