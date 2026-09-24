class SalaryRecordsController < ApplicationController
  before_action :set_employee, only: %i[new create]

  def new
    @currencies = Currency.order(:code)
    @components = SalaryComponent.active.order(:name)
  end

  def create
    @currencies = Currency.order(:code)
    @components = SalaryComponent.active.order(:name)

    result = SalaryRevisionService.new(
      employment: @employee.current_employment,
      currency: Currency.find(params[:currency_id]),
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

  def set_employee
    @employee = Employee.find(params[:employee_id])

    return if @employee.current_employment

    redirect_to employee_path(@employee), alert: "This employee has no employment record yet."
  end

  def component_amounts_param
    permitted = params.permit(components: {}).to_h[:components] || {}

    permitted.each_with_object({}) do |(component_id, amount), amounts|
      next if amount.blank?

      amounts[SalaryComponent.find(component_id)] = amount
    end
  end
end
