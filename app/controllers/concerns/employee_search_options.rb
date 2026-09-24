# Loads the dropdown collections the shared employee search form renders.
module EmployeeSearchOptions
  extend ActiveSupport::Concern

  private

  def load_employee_search_options
    @departments = Department.order(:name)
    @job_titles = JobTitle.order(:name)
    @countries = Country.order(:name)
  end
end
