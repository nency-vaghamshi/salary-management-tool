class PayrollRunsController < ApplicationController
  include EmployeeSearchOptions

  before_action :set_payroll_run, only: :show
  helper_method :employee_search_active?

  def index
    @pagy, @payroll_runs = pagy(PayrollRun.order(period_start: :desc))
  end

  def new
    @payroll_run = PayrollRun.new
  end

  def create
    @payroll_run = PayrollRun.new(payroll_run_params)

    if @payroll_run.save
      result = PayrollCalculator.new(@payroll_run).call
      redirect_to @payroll_run, notice: run_summary(result)
    else
      render :new, status: :unprocessable_content
    end
  end

  def show
    load_employee_search_options
    load_line_items
  end

  private

  # The search runs as a subquery (employee_id IN (SELECT ...)), so filtering
  # stays in Postgres and pagination still applies to the filtered result.
  def load_line_items
    line_items = @payroll_run.payroll_line_items
                             .includes(:employee, salary_record: [ :currency, :salary_record_components ])
                             .order(:employee_id)
    line_items = line_items.where(employee_id: employee_query.filtered.select(:id)) if employee_search_active?

    @pagy, @line_items = pagy(line_items)
  end

  def employee_query
    @employee_query ||= EmployeeQuery.new(params)
  end

  def employee_search_active?
    employee_query.filtering?
  end

  def set_payroll_run
    @payroll_run = PayrollRun.find(params[:id])
  end

  def run_summary(result)
    return "Processed #{result.processed_count} employee(s)." if result.skipped.empty?

    "Processed #{result.processed_count} employee(s), skipped #{result.skipped.count}."
  end

  def payroll_run_params
    params.require(:payroll_run).permit(:period_start, :period_end)
  end
end
