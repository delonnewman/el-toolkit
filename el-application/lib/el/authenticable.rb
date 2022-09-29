# frozen_string_literal: true

module El
  # Authentication for applications
  module Authenticable
    module ApplicationInstanceMethods
      NOT_AUTHORIZED = [401, {}, ['Not Authorized']].freeze

      # TODO: Generalize this perhaps the notion of a request interceptor could be useful.
      # (see https://github.com/macourtney/Conjure/wiki/How-to-create-a-controller-interceptor)
      def dispatch_request(request)
        auth = request.options[:authenticate]
        if auth.nil? || auth == true and request.session.nil? || request.session[:current_user_id].nil?
          NOT_AUTHORIZED
        elsif request.session && (user_id = request.session[:current_user_id])
          super(request.include_params(current_user: users.find_by!(id: user_id)))
        else
          super(request)
        end
      end
    end

    module Helpers
      def current_user
        request.params[:current_user]
      end

      def login!(user)
        request.session[:current_user_id] = user.id
        request.params[:current_user] = user
      end

      def logout!
        request.session.delete(:current_user_id)
        request.params.delete(:current_user)
      end

      # If no arguments are given return true if a user is authenticated
      # otherwise return false. If a role is specified with "as" return
      # true if the user is authenticated and is assigned to the given role
      # if the user is not assigned to the role return false, otherwise
      # return nil.
      #
      # @option as [String] a role name to test
      #
      # @return [Boolean, nil]
      def authenticated?(as: nil)
        return !!current_user if as.nil?

        current_user&.role?(as)
      end
    end

    ControllerInstanceMethods = Helpers
    ViewInstanceMethods = Helpers
  end
end
