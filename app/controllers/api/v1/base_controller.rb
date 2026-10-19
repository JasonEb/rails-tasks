module Api
  module V1
    # Shared auth and error handling for every v1 endpoint.
    # Clients send `Authorization: Bearer <token>`; endpoints that allow
    # anonymous access skip `authenticate!`.
    class BaseController < ApplicationController
      include ActionController::HttpAuthentication::Token::ControllerMethods

      class Forbidden < StandardError; end

      before_action :authenticate!

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActionController::ParameterMissing, with: :render_bad_request
      rescue_from Forbidden, with: :render_forbidden

      private

      attr_reader :current_user

      def authenticate!
        @current_user = authenticate_with_http_token do |token, _options|
          User.find_by(auth_token: token)
        end

        render_unauthorized unless @current_user
      end

      def authorize_owner!(record_owner_id)
        raise Forbidden unless record_owner_id == current_user.id
      end

      def render_errors(record)
        render json: { errors: record.errors.to_hash }, status: :unprocessable_content
      end

      def render_unauthorized(message = "Not authenticated")
        render json: { error: message }, status: :unauthorized
      end

      def render_not_found
        render json: { error: "Not found" }, status: :not_found
      end

      def render_bad_request(error)
        render json: { error: error.message }, status: :bad_request
      end

      def render_forbidden
        render json: { error: "You are not allowed to do that" }, status: :forbidden
      end
    end
  end
end
