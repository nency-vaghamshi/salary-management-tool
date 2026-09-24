# Single home for "which employees match these criteria". Every criterion is
# optional: a blank param is not applied, so empty criteria match everyone.
#
#   EmployeeQuery.new(params).roster   # listing: eager-loaded + sorted
#   EmployeeQuery.new(params).filtered # composable: no ORDER BY / DISTINCT,
#                                      # safe as an `IN (subquery)`
class EmployeeQuery
  FILTER_KEYS = %i[q department_id job_title_id nationality_country_id residence_country_id
                   payroll_country_id employment_status].freeze
  EMPLOYEE_COLUMN_FILTERS = %i[department_id job_title_id nationality_country_id residence_country_id].freeze
  SORTABLE_COLUMNS = %w[employee_number first_name last_name email created_at].freeze
  DEFAULT_SORT = "employee_number".freeze

  # Restricts the employments join to each employee's current employment,
  # mirroring Employee#current_employment (open-ended one if present,
  # otherwise the most recently started) so payroll-country/status filters
  # match what the pages display, without loading employments into Ruby.
  CURRENT_EMPLOYMENT_SQL = <<~SQL.squish
    employments.id = (
      SELECT e2.id FROM employments e2
      WHERE e2.employee_id = employees.id
      ORDER BY (e2.end_date IS NULL) DESC, e2.start_date DESC
      LIMIT 1
    )
  SQL

  def initialize(params, scope: Employee.all)
    @params = params
    @scope = scope
  end

  def filtered
    filter_by_employment(filter_by_attributes(search(scope)))
  end

  def roster
    relation = filtered.includes(:department, :job_title, :nationality_country, :residence_country,
                                 employments: [ :payroll_country, { salary_records: %i[currency salary_record_components] } ])
    sort(relation)
  end

  def filtering?
    FILTER_KEYS.any? { |key| params[key].present? }
  end

  private

  attr_reader :params, :scope

  def search(relation)
    query = params[:q].presence
    return relation unless query

    pattern = "%#{Employee.sanitize_sql_like(query.strip)}%"
    relation.where(
      "employees.employee_number ILIKE :pattern OR employees.first_name ILIKE :pattern " \
      "OR employees.last_name ILIKE :pattern OR employees.email ILIKE :pattern",
      pattern: pattern
    )
  end

  def filter_by_attributes(relation)
    EMPLOYEE_COLUMN_FILTERS.reduce(relation) do |filtered_relation, column|
      params[column].present? ? filtered_relation.where(column => params[column]) : filtered_relation
    end
  end

  def filter_by_employment(relation)
    return relation if params[:payroll_country_id].blank? && params[:employment_status].blank?

    relation = relation.joins(:employments).where(CURRENT_EMPLOYMENT_SQL)
    relation = relation.where(employments: { payroll_country_id: params[:payroll_country_id] }) if params[:payroll_country_id].present?
    relation = relation.where(employments: { status: params[:employment_status] }) if params[:employment_status].present?
    relation
  end

  def sort(relation)
    column = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : DEFAULT_SORT
    direction = params[:direction] == "desc" ? "desc" : "asc"

    relation.order(column => direction).distinct
  end
end
