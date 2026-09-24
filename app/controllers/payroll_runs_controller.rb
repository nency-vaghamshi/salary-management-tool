class PayrollRunsController < ApplicationController
  before_action :set_payroll_run, only: :show

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
    load_line_items
  end

  private

  def load_line_items
    @pagy, @line_items = pagy(
      @payroll_run.payroll_line_items
                  .includes(:employee, salary_record: [ :currency, :salary_record_components ])
                  .order(:employee_id)
    )
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
