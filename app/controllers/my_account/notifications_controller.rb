module MyAccount
  class NotificationsController < ApplicationController
    layout 'my_account'
    before_action :authenticate_user!
    before_action :set_company
    before_action :set_notification, only: [:show, :mark_as_read]
    
    def index
      @notifications = @company.notifications.order(created_at: :desc).page(params[:page]).per(20)
    end
    
    def show
      @notification = @company.notifications.find(params[:id])
      @notification.mark_as_read! unless @notification.read?
    end
    
    def mark_as_read
      @notification.mark_as_read!
      
      respond_to do |format|
        format.json { head :no_content }
        format.html { redirect_back(fallback_location: notifications_path) }
      end
    end
    
    private
    
    def set_company
      @company = current_user.company
      redirect_to root_path, alert: "You need to create a company first" unless @company
    end
    
    def set_notification
      @notification = @company.notifications.find(params[:id])
    end
  end
end
