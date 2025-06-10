module MyAccount
  class ProfilesController < ApplicationController
    def show
      @user = current_user
      @company = current_user.company if current_user.business_owner?
      @csv_uploads = current_user.csv_uploads.order(created_at: :desc)
    end

    def my_profile
      @user = current_user
    end

    def update_profile
      @user = current_user

      # Handle avatar replacement
      if params[:user][:avatar].present? && @user.avatar.attached?
        @user.avatar.purge
      end

      if @user.update(user_params)
        if params[:user][:avatar].present?
          if @user.avatar.attached?
            storage_service = Rails.application.config.active_storage.service
            blob = @user.avatar.blob
            redirect_to my_profile_path, notice: "#{t('profile.avatar_updated')} (Using: #{storage_service}, File: #{blob.filename}, ID: #{blob.key})"
          else
            redirect_to my_profile_path, notice: "#{t('profile.avatar_updated')} (Attachment failed)"
          end
        else
          redirect_to my_profile_path, notice: t("profile.updated_successfully")
        end
      else
        render :my_profile, status: :unprocessable_entity
      end
    end

    def update_password
      @user = current_user

      if @user.update_with_password(password_params)
        bypass_sign_in(@user)
        redirect_to my_profile_path, notice: t("profile.password_updated")
      else
        flash.now[:alert] = @user.errors.full_messages.join(", ")
        render :my_profile, status: :unprocessable_entity
      end
    end

    private

    def user_params
      params.require(:user).permit(:first_name, :last_name, :email, :avatar)
    end

    def password_params
      params.require(:user).permit(:current_password, :password, :password_confirmation)
    end
  end
end
