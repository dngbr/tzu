module MyAccount
  class CompanySwitcherController < BaseController
    skip_before_action :set_company, only: [:switch]
    
    def switch
      company_id = params[:company_id]
      
      # Verify the company belongs to the current user
      if company_id.present? && current_user.company&.id.to_s == company_id
        # Store the selected company ID in the session
        session[:current_company_id] = company_id
        redirect_back fallback_location: my_account_root_path, notice: "Company switched successfully"
      else
        redirect_back fallback_location: my_account_root_path, alert: "Invalid company selection"
      end
    end
  end
end
