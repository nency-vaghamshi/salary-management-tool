module EmployeesHelper
  def employee_sort_link(column, label)
    direction = params[:sort] == column && params[:direction] != "desc" ? "desc" : "asc"
    active = params[:sort] == column || (params[:sort].blank? && column == EmployeeQuery::DEFAULT_SORT)
    query = params.to_unsafe_h.merge(sort: column, direction: direction).except(:controller, :action, :page)

    link_to label, employees_path(query), class: "flex items-center gap-1 #{'text-gray-900 font-semibold' if active}"
  end
end
