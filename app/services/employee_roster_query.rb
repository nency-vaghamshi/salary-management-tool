# Builds the filtered, searched, and sorted Employee relation behind the
# roster list. Kept separate from the controllers so the same query backs
# both the HTML page and the JSON API without duplicating the logic.
class EmployeeRosterQuery
  SORTABLE_COLUMNS = %w[employee_number first_name last_name email created_at].freeze
  DEFAULT_SORT = "employee_number".freeze

  # Restricts the employments join to each employee's current employment,
  # mirroring Employee#current_employment (open-ended one if present,
  # otherwise the most recently started) so payroll-country/status filters
  # match what the roster displays, without loading employments into Ruby.
  CURRENT_EMPLOYMENT_SQL = <<~SQL.squish
    employments.id = (
      SELECT e2.id FROM employments e2
      WHERE e2.employee_id = employees.id
      ORDER BY (e2.end_date IS NULL) DESC, e2.start_date DESC
      LIMIT 1
    )
  SQL

  def initialize(params)
    @params = params
  end

  def call
    scope = Employee.includes(:department, :job_title, :nationality_country, :residence_country,
                               employments: { salary_records: %i[currency salary_record_components] })

    scope = apply_search(scope)
    scope = apply_filters(scope)
    apply_sort(scope)
  end

  private

  attr_reader :params

  def apply_search(scope)
    query = params[:q].presence
    return scope unless query

    pattern = "%#{query}%"
    scope.where(
      "employee_number ILIKE :pattern OR first_name ILIKE :pattern OR last_name ILIKE :pattern OR email ILIKE :pattern",
      pattern: pattern
    )
  end

  def apply_filters(scope)
    scope = scope.where(department_id: params[:department_id]) if params[:department_id].present?
    scope = scope.where(job_title_id: params[:job_title_id]) if params[:job_title_id].present?

    if params[:payroll_country_id].present? || params[:employment_status].present?
      scope = scope.joins(:employments).where(CURRENT_EMPLOYMENT_SQL)
      scope = scope.where(employments: { payroll_country_id: params[:payroll_country_id] }) if params[:payroll_country_id].present?
      scope = scope.where(employments: { status: params[:employment_status] }) if params[:employment_status].present?
    end

    scope
  end

  def apply_sort(scope)
    column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : DEFAULT_SORT
    direction = params[:direction] == "desc" ? "desc" : "asc"

    scope.order(column => direction).distinct
  end
end
