# Everything a payslip displays, derived from the frozen payroll line item
# (net pay and tax as actually paid) and the salary record it was paid from.
class PayslipStatement
  Earning = Struct.new(:name, :amount, :taxable, keyword_init: true)

  attr_reader :payslip, :line_item, :payroll_run, :salary_record, :employee

  delegate :reference, :generated_at, to: :payslip
  delegate :currency, to: :salary_record

  def initialize(payslip)
    @payslip = payslip
    @line_item = payslip.payroll_line_item
    @payroll_run = line_item.payroll_run
    @salary_record = line_item.salary_record
    @employee = line_item.employee
  end

  def net_pay = line_item.amount
  def tax = line_item.tax_amount
  def gross_pay = net_pay + tax

  def employment = salary_record.employment
  def annual_gross = salary_record.total_amount

  # Each annual component, pro-rated to this period. Rounding every line to
  # cents can drift from the gross by a cent or two, so that remainder is
  # booked to the largest line and Earnings - Tax always equals Net pay.
  def earnings
    @earnings ||= begin
      factor = payroll_run.proration_factor
      lines = salary_record.salary_record_components.sort_by { |component| -component.amount }.map do |component|
        Earning.new(name: component.salary_component.name, amount: (component.amount * factor).round(2),
                    taxable: component.salary_component.is_taxable)
      end
      remainder = gross_pay - lines.sum(&:amount)
      lines.first.amount += remainder if lines.any? && remainder.abs < 1
      lines
    end
  end
end
