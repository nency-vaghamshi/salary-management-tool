class Api::V1::EmployeesController < Api::V1::BaseController
  before_action :set_employee, only: %i[show update destroy]

  def index
    pagy, employees = pagy(EmployeeRosterQuery.new(params).call)

    render json: {
      employees: employees.map { |employee| serialize(employee) },
      pagination: pagy_metadata(pagy)
    }
  end

  def show
    render json: { employee: serialize(@employee) }
  end

  def create
    employee = Employee.new(employee_params)

    if employee.save
      render json: { employee: serialize(employee) }, status: :created
    else
      render json: { errors: employee.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if @employee.update(employee_params)
      render json: { employee: serialize(@employee) }
    else
      render json: { errors: @employee.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    @employee.destroy
    head :no_content
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(
      :employee_number, :first_name, :last_name, :email,
      :department_id, :job_title_id, :nationality_country_id, :residence_country_id
    )
  end

  def pagy_metadata(pagy)
    { page: pagy.page, pages: pagy.pages, count: pagy.count }
  end

  def serialize(employee)
    {
      id: employee.id,
      employee_number: employee.employee_number,
      first_name: employee.first_name,
      last_name: employee.last_name,
      email: employee.email,
      department: employee.department.name,
      job_title: employee.job_title.name,
      nationality_country: employee.nationality_country&.name,
      residence_country: employee.residence_country&.name,
      payroll_country: employee.current_employment&.payroll_country&.name,
      employment_status: employee.current_employment&.status,
      current_salary: employee.current_salary_record&.total_amount,
      currency: employee.current_salary_record&.currency&.code
    }
  end
end
