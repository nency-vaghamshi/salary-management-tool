class PayslipsController < ApplicationController
  def show
    payslip = Payslip.includes(
      payroll_line_item: [
        :payroll_run,
        { employee: %i[department job_title] },
        { salary_record: [ :currency, { employment: :payroll_country }, { salary_record_components: :salary_component } ] }
      ]
    ).find(params[:id])

    @statement = PayslipStatement.new(payslip)
  end
end
