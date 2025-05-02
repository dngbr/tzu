module MyAccount
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :set_company
    layout 'my_account'
    
    private
    
    def set_company
      # If there's a company ID in the session, use that company
      if session[:current_company_id].present?
        @company = current_user.company
        
        # If the user doesn't have a company or the company ID doesn't match,
        # clear the session and use the default company
        if @company.nil? || @company.id.to_s != session[:current_company_id]
          session.delete(:current_company_id)
        end
      else
        @company = current_user.company
      end
      
      # Redirect if no company exists
      redirect_to new_my_account_company_path, alert: "You need to create a company first" unless @company
    end
  end
end
