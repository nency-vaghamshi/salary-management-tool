class Api::V1::SalaryRecordsController < Api::V1::BaseController
  def create
    employment = Employment.find(params[:employment_id])
    currency = Currency.find(params[:currency_id])

    result = SalaryRevisionService.new(
      employment: employment,
      currency: currency,
      effective_from: params[:effective_from],
      component_amounts: component_amounts_param
    ).call

    if result.success?
      render json: { salary_record: serialize(result.salary_record) }, status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_content
    end
  end

  def show
    salary_record = SalaryRecord.includes(:currency, employment: :payroll_country, salary_record_components: :salary_component)
                                 .find(params[:id])
    estimate = SalaryTaxEstimator.new(salary_record).call

    render json: { salary_record: serialize(salary_record).merge(tax_estimate: serialize_tax_estimate(estimate)) }
  end

  private

  def component_amounts_param
    permitted = params.permit(components: {}).to_h[:components] || {}

    permitted.each_with_object({}) do |(component_id, amount), amounts|
      next if amount.blank?

      amounts[SalaryComponent.find(component_id)] = amount
    end
  end

  def serialize(salary_record)
    {
      id: salary_record.id,
      employment_id: salary_record.employment_id,
      currency: salary_record.currency.code,
      effective_from: salary_record.effective_from,
      effective_to: salary_record.effective_to,
      status: salary_record.status,
      total_amount: salary_record.total_amount,
      components: salary_record.salary_record_components.map do |component|
        { name: component.salary_component.name, amount: component.amount }
      end
    }
  end

  def serialize_tax_estimate(estimate)
    return { error: estimate.error } if estimate.error

    {
      taxable_income: estimate.taxable_income,
      tax_amount: estimate.tax_amount,
      net_amount: estimate.net_amount
    }
  end
end
