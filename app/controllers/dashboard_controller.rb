# Company-wide overview, scoped to one salary currency at a time. There is no
# exchange-rate data, so summing amounts across currencies would be
# meaningless; instead every metric covers only salaries (and payroll line
# items) in the selected currency. All aggregation happens in Postgres.
class DashboardController < ApplicationController
  CurrencyOption = Struct.new(:id, :code, :name, :symbol, :employee_count, keyword_init: true) do
    # Some imported currencies store the code as their name ("EUR"); skip the
    # redundant "EUR — EUR" in that case.
    def label
      name.blank? || name == code ? code : "#{code} — #{name}"
    end
  end
  MonthlyPayroll = Struct.new(:month, :employee_count, :net_total, :tax_total, keyword_init: true) do
    def gross_total
      net_total + tax_total
    end
  end

  DepartmentStat = Struct.new(:name, :employee_count, :total_compensation, keyword_init: true) do
    def average_compensation
      return 0 if employee_count.zero?

      total_compensation / employee_count
    end
  end

  PAYROLL_MONTHS_SHOWN = 12

  def index
    @currency_options = fetch_currency_options
    @currency = selected_currency
    return unless @currency

    @department_stats = fetch_department_stats.sort_by { |stat| -stat.average_compensation }
    # Every employee belongs to exactly one department, so the per-department
    # figures already sum to the company totals — no separate query needed.
    @total_employees = @department_stats.sum(&:employee_count)
    @total_annual_compensation = @department_stats.sum(0.to_d, &:total_compensation)
    @average_salary = @total_employees.positive? ? @total_annual_compensation / @total_employees : 0

    @payroll_months = payroll_window
    @monthly_payrolls = fetch_monthly_payrolls
    @payroll_chart = PayrollCostChart.new(@monthly_payrolls, months: @payroll_months)
  end

  private

  # Only currencies someone is actually paid in, so every option shows data.
  def fetch_currency_options
    Employment.active
              .joins(salary_records: :currency)
              .where(salary_records: { status: "active" })
              .group("currencies.id", "currencies.code", "currencies.name", "currencies.symbol")
              .order("currencies.code")
              .pluck(Arel.sql("currencies.id"), Arel.sql("currencies.code"), Arel.sql("currencies.name"),
                     Arel.sql("currencies.symbol"), Arel.sql("COUNT(DISTINCT employments.id)"))
              .map { |id, code, name, symbol, count| CurrencyOption.new(id:, code:, name:, symbol:, employee_count: count) }
  end

  # Falls back to the currency most employees are paid in, so the page is
  # useful on first load and an unknown/tampered currency_id can't break it.
  def selected_currency
    @currency_options.find { |option| option.id.to_s == params[:currency_id].to_s } ||
      @currency_options.max_by(&:employee_count)
  end

  # The last PAYROLL_MONTHS_SHOWN calendar months, oldest first, ending this month.
  def payroll_window
    current_month = Date.current.beginning_of_month
    (PAYROLL_MONTHS_SHOWN - 1).downto(0).map { |offset| current_month << offset }
  end

  def fetch_department_stats
    Employee.joins(:department, employments: { salary_records: :salary_record_components })
             .where(employments: { status: "active", salary_records: { status: "active", currency_id: @currency.id } })
             .group("departments.name")
             .pluck(
               Arel.sql("departments.name"),
               Arel.sql("COUNT(DISTINCT employees.id)"),
               Arel.sql("COALESCE(SUM(salary_record_components.amount), 0)")
             )
             .map { |name, count, total| DepartmentStat.new(name: name, employee_count: count, total_compensation: total) }
  end

  # What was actually paid, from completed runs' frozen line items — not a
  # recalculation — grouped by the month each run's period starts in.
  def fetch_monthly_payrolls
    month = "DATE_TRUNC('month', payroll_runs.period_start)"

    PayrollLineItem.joins(:payroll_run, :salary_record)
                   .where(payroll_runs: { status: "completed", period_start: @payroll_months.first..@payroll_months.last.end_of_month },
                          salary_records: { currency_id: @currency.id })
                   .group(Arel.sql(month))
                   .order(Arel.sql("#{month} DESC"))
                   .pluck(Arel.sql(month), Arel.sql("COUNT(DISTINCT payroll_line_items.employee_id)"),
                          Arel.sql("SUM(payroll_line_items.amount)"), Arel.sql("SUM(payroll_line_items.tax_amount)"))
                   .map do |month_start, count, net, tax|
                     MonthlyPayroll.new(month: month_start.to_date, employee_count: count, net_total: net, tax_total: tax)
                   end
  end
end
