module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate!

      def create
        user = User.authenticate_by(email: params[:email].to_s, password: params[:password].to_s)

        if user
          render json: { user: UserResource.new(user).to_h, token: user.auth_token }
        else
          render_unauthorized("Invalid email or password")
        end
      end
    end
  end
end
