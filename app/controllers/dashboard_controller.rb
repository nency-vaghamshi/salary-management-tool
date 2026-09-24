# Company-wide overview. Every metric here is one aggregate SQL query (COUNT/
# SUM computed by Postgres, not by summing loaded AR objects in Ruby) per
# design-best-practises.md's dashboard guidance, keeping the whole page to
# three round trips regardless of employee count.
class DashboardController < ApplicationController
  CountryStat = Struct.new(:name, :employee_count, :total_compensation, keyword_init: true) do
    def share_of(total)
      return 0 if total.zero?

      (total_compensation / total * 100).round(1)
    end

    def employee_share_of(total)
      return 0 if total.zero?

      (employee_count.to_f / total * 100).round(1)
    end
  end

  DepartmentStat = Struct.new(:name, :employee_count, :total_compensation, keyword_init: true) do
    def average_compensation
      return 0 if employee_count.zero?

      total_compensation / employee_count
    end
  end

  TOP_COUNTRIES_SHOWN = 10

  def index
    @total_employees = Employee.count

    country_stats = fetch_country_stats
    @number_of_countries = country_stats.size
    @total_annual_compensation = country_stats.sum(&:total_compensation)
    @average_salary = @total_employees.positive? ? @total_annual_compensation / @total_employees : 0
    @countries_by_compensation = country_stats.sort_by { |stat| -stat.total_compensation }.first(TOP_COUNTRIES_SHOWN)
    @countries_by_headcount = country_stats.sort_by { |stat| -stat.employee_count }.first(TOP_COUNTRIES_SHOWN)

    @department_stats = fetch_department_stats.sort_by { |stat| -stat.average_compensation }
    @number_of_departments = @department_stats.size
  end

  private

  # One employee has effectively one active employment, so COUNT(DISTINCT
  # employments.id) here is a headcount, not a row count inflated by the
  # component join.
  def fetch_country_stats
    Employment.active
              .joins(:payroll_country, salary_records: :salary_record_components)
              .where(salary_records: { status: "active" })
              .group("countries.name")
              .pluck(
                Arel.sql("countries.name"),
                Arel.sql("COUNT(DISTINCT employments.id)"),
                Arel.sql("COALESCE(SUM(salary_record_components.amount), 0)")
              )
              .map { |name, count, total| CountryStat.new(name: name, employee_count: count, total_compensation: total) }
  end

  def fetch_department_stats
    Employee.joins(:department, employments: { salary_records: :salary_record_components })
             .where(employments: { status: "active", salary_records: { status: "active" } })
             .group("departments.name")
             .pluck(
               Arel.sql("departments.name"),
               Arel.sql("COUNT(DISTINCT employees.id)"),
               Arel.sql("COALESCE(SUM(salary_record_components.amount), 0)")
             )
             .map { |name, count, total| DepartmentStat.new(name: name, employee_count: count, total_compensation: total) }
  end
end
