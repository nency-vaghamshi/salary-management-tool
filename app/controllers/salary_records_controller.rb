class SalaryRecordsController < ApplicationController
  before_action :set_employee, only: %i[new create]
  before_action :load_form_options, only: %i[new create]

  def new
  end

  def create
    result = SalaryRevisionService.new(
      employment: @employment || build_first_employment,
      currency: Currency.find_by(id: params[:currency_id]),
      effective_from: params[:effective_from],
      component_amounts: component_amounts_param
    ).call

    if result.success?
      redirect_to employee_path(@employee), notice: "Salary revised."
    else
      @errors = result.errors
      render :new, status: :unprocessable_content
    end
  end

  def show
    @salary_record = SalaryRecord.includes(:currency, employment: %i[employee payroll_country], salary_record_components: :salary_component)
                                  .find(params[:id])
    @tax_estimate = SalaryTaxEstimator.new(@salary_record).call
  end

  private

  # Captured once so the form's "first salary?" decision can't be flipped by
  # an unsaved employment built during a failed create.
  def set_employee
    @employee = Employee.find(params[:employee_id])
    @employment = @employee.current_employment
  end

  def load_form_options
    @currencies = Currency.order(:code)
    @components = SalaryComponent.active.order(:name)
    @countries = Country.order(:name) unless @employment
  end

  # A first salary has no employment to hang off yet, so the form collects
  # payroll country and start date. Built by id (not via @employee) so Rails'
  # has_many inversing doesn't add the unsaved record to @employee.employments.
  def build_first_employment
    Employment.new(
      employee_id: @employee.id,
      payroll_country_id: params[:payroll_country_id],
      start_date: params[:start_date],
      status: "active"
    )
  end

  def component_amounts_param
    permitted = params.permit(components: {}).to_h[:components] || {}

    permitted.each_with_object({}) do |(component_id, amount), amounts|
      next if amount.blank?

      amounts[SalaryComponent.find(component_id)] = amount
    end
  end
end
