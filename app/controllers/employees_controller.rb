class EmployeesController < ApplicationController
  include EmployeeSearchOptions

  before_action :set_employee, only: %i[show edit update destroy]
  before_action :set_form_collections, only: %i[new edit create update]

  def index
    @pagy, @employees = pagy(EmployeeQuery.new(params).roster)
    load_employee_search_options
  end

  def show
    @salary_history = SalaryRecord.joins(:employment)
                                   .where(employments: { employee_id: @employee.id })
                                   .includes(:currency, salary_record_components: :salary_component)
                                   .order(effective_from: :desc)
                                   .to_a
    # Who created each salary record, in one query for the whole history.
    @salary_audits = AuditLog.creations_of(@salary_history).includes(:actor).index_by(&:auditable_id)
    @payslips = Payslip.joins(payroll_line_item: :payroll_run)
                       .where(payroll_line_items: { employee_id: @employee.id })
                       .includes(payroll_line_item: [ :payroll_run, { salary_record: :currency } ])
                       .order("payroll_runs.period_start DESC")
    @tax_estimate = SalaryTaxEstimator.new(@employee.current_salary_record).call if @employee.current_salary_record
  end

  def new
    @employee = Employee.new
  end

  def create
    @employee = Employee.new(employee_params)

    if @employee.save
      redirect_to @employee, notice: "Employee created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @employee.update(employee_params)
      redirect_to @employee, notice: "Employee updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @employee.destroy
    redirect_to employees_path, notice: "Employee removed."
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def set_form_collections
    @departments = Department.order(:name)
    @job_titles = JobTitle.order(:name)
    @countries = Country.order(:name)
  end

  def employee_params
    params.require(:employee).permit(
      :employee_number, :first_name, :last_name, :email,
      :department_id, :job_title_id, :nationality_country_id, :residence_country_id
    )
  end
end
