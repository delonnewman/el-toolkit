# frozen_string_literal: true

require 'el/advice'
require_relative 'templating'

module El
  class Messenger < Advice
    advises Application, as: :app, delegating: %i[logger]

    include Templating

    def deliver!(message, *args)
      public_send(message, *args).wait!
    end

    DEFAULT_FROM = 'contact@delonnewman.name'

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
