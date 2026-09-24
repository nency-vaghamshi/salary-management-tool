# Generic progressive-bracket tax math. Knows nothing about employees,
# salaries, or countries by name — it only reads whatever brackets exist on
# the TaxConfiguration it's given, per updated_db.md #15/#16. Splitting the
# income across brackets keeps this correct for any country's schedule
# without a single country-specific branch.
class TaxCalculator
  class MissingTaxBracketsError < StandardError; end

  BracketResult = Struct.new(:min_income, :max_income, :rate, :taxable_amount, :tax, keyword_init: true)
  Result = Struct.new(:tax_amount, :breakdown)

  def initialize(tax_configuration:, taxable_income:)
    @tax_configuration = tax_configuration
    @taxable_income = taxable_income.to_d
  end

  def call
    if tax_configuration.tax_brackets.none?
      raise MissingTaxBracketsError, "No tax brackets configured for #{tax_configuration.country.name} (#{tax_configuration.tax_year})"
    end

    return Result.new(0.to_d, []) if taxable_income <= 0

    remaining = taxable_income
    breakdown = []

    tax_configuration.tax_brackets.sort_by(&:min_income).each do |bracket|
      break if remaining <= 0

      bracket_span = (bracket.max_income || taxable_income) - bracket.min_income
      taxable_in_bracket = [ remaining, bracket_span ].min
      next if taxable_in_bracket <= 0

      tax = (taxable_in_bracket * bracket.tax_rate / 100).round(2)
      breakdown << BracketResult.new(
        min_income: bracket.min_income, max_income: bracket.max_income,
        rate: bracket.tax_rate, taxable_amount: taxable_in_bracket, tax: tax
      )
      remaining -= taxable_in_bracket
    end

    Result.new(breakdown.sum(0.to_d, &:tax), breakdown)
  end

  private

  attr_reader :tax_configuration, :taxable_income
end
