module MyAccount
  class CompaniesController < ApplicationController
    before_action :set_company, only: [ :show, :edit, :update ]
    before_action :ensure_business_owner, only: [ :new, :create ]
    before_action :ensure_company_owner, only: [ :edit, :update ]

    def new
      # Check if user already has a company
      if current_user.company.present?
        # Use company's preferred language for locale
        locale = current_user.company.preferred_language.present? ? current_user.company.preferred_language : I18n.default_locale
        redirect_to my_account_my_company_path(locale: locale), notice: "You already have a company profile."
      else
        @company = Company.new
      end
    end

    def create
      @company = Company.new(company_params)
      @company.user = current_user

      if @company.save
        # Use company's preferred language for locale
        locale = @company.preferred_language.present? ? @company.preferred_language : I18n.default_locale
        redirect_to my_account_my_company_path(locale: locale), notice: "Company was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @company.update(company_params)
        # Redirect with the company's preferred language as locale parameter
        locale = @company.preferred_language.present? ? @company.preferred_language : I18n.default_locale
        redirect_to my_account_my_company_path(locale: locale), notice: "Company was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def show
    end

    def my_company
      @company = current_user.company

      # If user doesn't have a company yet, redirect to create one
      unless @company
        redirect_to new_my_account_company_path, notice: t("company.create_first")
        nil
      end
    end

    private

    def set_company
      @company = Company.find(params[:id])
    end

    def company_params
      params.require(:company).permit(:name, :description, :address, :phone, :website, :brand_photo, :background_photo, :preferred_language)
    end

    def ensure_business_owner
      unless current_user.business_owner?
        redirect_to root_path, alert: "Only business owners can access this page."
      end
    end

    def ensure_company_owner
      unless @company.user == current_user
        redirect_to root_path, alert: "You can only edit your own company."
      end
    end
  end
end
