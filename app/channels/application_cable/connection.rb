module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.add_tags "ActionCable", current_user.email
    end

    private

    def find_verified_user
      # Try to find user from Devise's Warden authentication
      if env["warden"].authenticated?
        verified_user = env["warden"].user
        logger.info "ActionCable connection established for user: #{verified_user.email}"
        verified_user
      else
        # If Warden auth fails, try cookie-based auth as fallback
        verified_user = User.find_by(id: cookies.encrypted[:user_id])
        if verified_user
          logger.info "ActionCable connection established via cookie for user: #{verified_user.email}"
          verified_user
        else
          logger.error "ActionCable connection rejected: unauthorized connection attempt"
          reject_unauthorized_connection
        end
      end
    end
  end
end
