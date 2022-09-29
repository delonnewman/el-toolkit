# frozen_string_literal: true

# rubocop: disable Metrics/ModuleLength

require 'cgi'

module El
  module TemplateHelpers
    include CGI::Util

    def link_to(path, content = nil, escape: true, title: nil, **options)
      raise 'Content is required for a link' if !block_given? && content.nil?

      content = yield if block_given?
      content = escape_html(content) if escape

      classes = options[:class]
      classes = classes.join(' ') if classes.is_a?(Enumerable)

      "<a href=\"#{url_for(path)}\" title=\"#{title}\" class=\"#{classes}\">#{content}</a>"
    end

    def pluralize(number, string)
      number == 1 ? "#{number} #{string}" : "#{number} #{Inflection.plural string}"
    end

    YEAR_IN_SECONDS = 31_104_000
    MONTH_IN_SECONDS = 2_592_000
    WEEK_IN_SECONDS = 604_800
    DAY_IN_SECONDS = 86_400
    HOUR_IN_SECONDS = 3600

    def time_ago_in_words(time)
      diff = Time.now - time
      suffix = diff.negative? ? 'from now' : 'ago'
      diff_ = diff.abs

      if diff_ > YEAR_IN_SECONDS
        "#{pluralize (diff_ / YEAR_IN_SECONDS).floor, 'year'} #{suffix}"
      elsif diff_ > MONTH_IN_SECONDS
        "#{pluralize (diff_ / MONTH_IN_SECONDS).floor, 'month'} #{suffix}"
      elsif diff_ > WEEK_IN_SECONDS
        "#{pluralize (diff_ / WEEK_IN_SECONDS).floor, 'week'} #{suffix}"
      elsif diff_ > DAY_IN_SECONDS
        "#{pluralize (diff_ / DAY_IN_SECONDS).floor, 'day'} #{suffix}"
      elsif diff_ > HOUR_IN_SECONDS
        "#{pluralize (diff_ / HOUR_IN_SECONDS).floor, 'hour'} #{suffix}"
      elsif diff_ > 60
        "#{pluralize (diff_ / 60).floor, 'minute'} #{suffix}"
      else
        'just now'
      end
    end

    # Font Awesome integration
    def icon(name, text = nil, type: 'fas')
      code = "<i class=\"#{type} fa-#{name}\"></i>"
      return code unless text

      "#{code}&nbsp;#{text}"
    end

    def input_field(name, value = params[name.to_s], type: 'text')
      "<input type=\"#{type}\" class=\"form-control\" id=\"#{name}\" name=\"#{name}\" value=\"#{value}\">"
    end
    alias text_field input_field

    def datetime_field(name, value = params[name.to_s])
      input_field name, value, type: 'datetime-local'
    end

    def password_field(name, value = params[name.to_s])
      input_field name, value, type: 'password'
    end

    def email_field(name, value = params[name.to_s])
      input_field name, value, type: 'email'
    end

    def select_field(name, options, selected: nil)
      opts =
        case options
        when Hash
          options.map do |k, v|
            if v == selected
              "<option selected value=\"#{k}\">#{h v}</option>"
            else
              "<option value=\"#{k}\">#{h v}</option>"
            end
          end
        else
          options.map do |v|
            if v == selected
              "<option selected>#{h v}</option>"
            else
              "<option>#{h v}</option>"
            end
          end
        end

      select = "<select name=\"#{name}\">#{opts.join('')}</select>"
      if (errors = view.dig(:errors, name.to_sym))
        "#{select}<div class=\"invalid-feedback\">#{errors.join(', ')}</div>"
      else
        select
      end
    end

    def radio_buttons(name, options, selected: nil, inline: true)
      radios =
        options.each_with_index.map do |(id, text), i|
          "<div class=\"form-check #{inline ? 'form-check-inline' : ''}\">
               <input class=\"form-check-input\" #{selected == id ? 'checked' : ''}
                      type=\"radio\" name=\"#{name}\" id=\"#{name}#{i}\" value=\"#{id}\">
               <label class=\"form-check-label\" for=\"#{name}#{i}\">#{text}</label>
            </div>"
        end

      radios.join('')
    end

    BOOLEAN_OPTIONS = { true => 'Yes', false => 'No' }.freeze

    def boolean_field(name, value)
      radio_buttons(name, BOOLEAN_OPTIONS, selected: value)
    end

    def entity_field(name, entity_class, **options)
      opts = entity_class.repository.map { |e| [e.id, e.to_s] }.to_h
      if opts.length < 5
        radio_buttons(name, opts, **options)
      else
        select_field(name, opts, **options)
      end
    end

    def form_field(attr, entity: nil, entity_class: entity.class)
      name = "#{entity_class.canonical_name}[#{attr.name}]"
      value = entity&.send(attr.name)
      if attr.password?
        password_field name
      elsif attr.time?
        datetime_field name, value
      elsif attr.boolean?
        boolean_field name, value
      elsif attr.email?
        email_field name, value
      elsif attr.entity?
        entity_field name, attr.value_class, selected: value&.id
      else
        text_field name, value
      end
    end
  end
end
