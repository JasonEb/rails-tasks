module Api
  module V1
    class UsersController < BaseController
      skip_before_action :authenticate!, only: :create

      def create
        user = User.new(user_params)

        if user.save
          render json: { user: UserResource.new(user).to_h, token: user.auth_token }, status: :created
        else
          render_errors(user)
        end
      end

      def me
        render json: { user: UserResource.new(current_user).to_h }
      end

      private

      def user_params
        params.expect(user: [ :email, :name, :password ])
      end
    end
  end
end
