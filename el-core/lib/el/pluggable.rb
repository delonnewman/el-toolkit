# frozen_string_literal: true

module El
  # Enable a class to work with plugins
  #
  #  @example
  #     class Controller
  #       extend Pluggable
  #     end
  #
  #     class Application
  #       extend Pluggable
  #     end
  #
  #     module Authentication
  #       module ApplicationInstanceMethods
  #         def dispatch_request(request)
  #           return super unless (user_id = request.session[:current_user_id])
  #
  #           super(request.include_params(current_user: users.find_by(id: user_id)))
  #         end
  #       end
  #
  #       module ControllerInstanceMethods
  #         def current_user
  #           request.params[:current_user]
  #         end
  #
  #         def logout!
  #           request.session.delete(:current_user_id)
  #           request.params.delete(:current_user)
  #         end
  #       end
  #     end
  #
  #     class ApplicationController < Controller
  #       plugin Authentication
  #     end
  #
  #     class MyApplication < Application
  #       plugin Authentication
  #     end
  #
  module Pluggable
    def self.[](prefix)
      Module.new.tap do |mod|
        mod.extend(self)
        mod.instance_variable_set(:@plugin_prefix, prefix)
      end
    end

    attr_reader :plugin_prefix

    def register_plugin(name, mod)
      plugins[name] = mod
    end

    def plugins
      @plugins ||= {}
    end

    def load_plugin(plugin)
      unless (plugin = plugins[name])
        require "el/#{plugin_preffix.downcase}/#{name}"
        raise Error, "plugin #{name} did not register itself correctly in #{self}" unless (plugin = plugins[name])
      end
      plugin
    end

    def extended(base)
      return unless base.is_a?(Class)

      prefix = plugin_prefix || base.name.split('::').last
      base.class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def self.plugin(plug)
          plug = load_plugin(plug) if plug.is_a?(Symbol)

          include(plug::#{prefix}InstanceMethods) if defined?(plug::#{prefix}InstanceMethods)
          extend(plug::#{prefix}ClassMethods)     if defined?(plug::#{prefix}ClassMethods)

          include(plug::InstanceMethods) if defined?(plug::InstanceMethods)
          extend(plug::ClassMethods)     if defined?(plug::ClassMethods)
        end
      RUBY
    end

    module_function :extended, :load_plugin, :register_plugin, :plugins, :plugin_prefix
  end
end
