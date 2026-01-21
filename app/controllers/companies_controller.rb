# frozen_string_literal: true

class CompaniesController < ApplicationController
  skip_before_action :set_current_company, only: [:edit, :update]
  before_action :set_or_build_company

  def show
    redirect_to edit_company_path
  end

  def edit
  end

  def create
    @company = Company.new(company_params)

    if @company.save
      current_user.update(company: @company)
      redirect_to edit_company_path, notice: "Settings saved.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update
    if @company.update(company_params)
      # Associate user with company if not already
      current_user.update(company: @company) if current_user.company.blank?

      redirect_to edit_company_path, notice: "Settings saved.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def remove_logo
    @company.logo.purge if @company.logo.attached?

    respond_to do |format|
      format.html { redirect_to edit_company_path, notice: "Logo removed." }
      format.turbo_stream { flash.now[:notice] = "Logo removed." }
    end
  end

  private

  def set_or_build_company
    @company = current_user.company || Company.new
  end

  def company_params
    params.require(:company).permit(
      :name,
      :logo,
      :address,
      :city,
      :state,
      :zip_code,
      :phone,
      :email,
      :license_number,
      :default_labor_markup,
      :default_material_markup,
      :default_terms,
      :default_payment_terms,
      :legal_boilerplate
    )
  end
end
