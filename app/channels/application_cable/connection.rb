module ApplicationCable
  # Browsers can't set headers on a WebSocket, so the client passes its
  # API token as a query param: ws://host/cable?token=<auth_token>.
  # Rails filters `token` from logs by default.
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token].presence
      user = token && User.find_by(auth_token: token)

      user || reject_unauthorized_connection
    end
  end
end
