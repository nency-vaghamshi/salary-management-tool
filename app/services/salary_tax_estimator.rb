# Gathers the employee-specific inputs TaxCalculator needs and hands them
# off to it. Tax country is always the employment's payroll_country_id, per
# updated_db.md #7 (Employment.payroll_country_id -> Country ->
# TaxConfiguration -> TaxBracket) — never nationality or residence.
class SalaryTaxEstimator
  Result = Struct.new(:gross_amount, :taxable_income, :tax_amount, :net_amount, :breakdown, :error, keyword_init: true)

  def initialize(salary_record)
    @salary_record = salary_record
  end

  def call
    tax_configuration = applicable_tax_configuration

    return error_result("No tax configuration found for #{payroll_country.name}") unless tax_configuration

    calculation = TaxCalculator.new(tax_configuration: tax_configuration, taxable_income: taxable_income).call

    Result.new(
      gross_amount: gross_amount,
      taxable_income: taxable_income,
      tax_amount: calculation.tax_amount,
      net_amount: gross_amount - calculation.tax_amount,
      breakdown: calculation.breakdown,
      error: nil
    )
  rescue TaxCalculator::MissingTaxBracketsError => e
    error_result(e.message)
  end

  private

  attr_reader :salary_record

  def gross_amount
    salary_record.total_amount
  end

  # Operates on the already-loaded association (not a fresh .where/.sum
  # query) so this stays cheap when called once per employee across a
  # whole-company payroll run rather than for a single employee's page.
  def taxable_income
    salary_record.salary_record_components
                  .select { |component| component.salary_component.is_taxable }
                  .sum(&:amount)
  end

  def payroll_country
    salary_record.employment.payroll_country
  end

  # One config per country in this dataset; picking the highest tax_year
  # covers a country ever having more than one active configuration.
  # Filters/sorts the preloaded array in Ruby rather than issuing a fresh
  # .where/.order query, for the same bulk-payroll-run reason as above.
  def applicable_tax_configuration
    payroll_country.tax_configurations.select { |config| config.status == "active" }.max_by(&:tax_year)
  end

  def error_result(message)
    Result.new(gross_amount: gross_amount, taxable_income: taxable_income, tax_amount: nil, net_amount: nil,
               breakdown: [], error: message)
  end
end
