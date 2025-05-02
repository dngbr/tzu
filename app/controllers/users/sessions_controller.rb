module Users
  class SessionsController < Devise::SessionsController
    # before_action :configure_sign_in_params, only: [:create]

    # GET /resource/sign_in
    # def new
    #   super
    # end

    # POST /resource/sign_in
    def create
      super do |resource|
        # Redirect to my_account after successful sign in
        return redirect_to my_account_root_path if resource.persisted?
      end
    end

    # DELETE /resource/sign_out
    def destroy
      super do
        # Turbo requires redirects be :see_other (303) to work properly with DELETE requests
        return redirect_to root_path, status: :see_other
      end
    end

    # protected

    # If you have extra params to permit, append them to the sanitizer.
    # def configure_sign_in_params
    #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
    # end
  end
end
