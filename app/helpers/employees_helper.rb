module EmployeesHelper
  # Column header that toggles sort direction, keeping the current filters.
  # Shows which column is sorted and in which direction.
  def employee_sort_link(column, label)
    active = params[:sort] == column || (params[:sort].blank? && column == EmployeeQuery::DEFAULT_SORT)
    descending = active && params[:direction] == "desc"
    query = params.to_unsafe_h.merge(sort: column, direction: active && !descending ? "desc" : "asc")
                  .except(:controller, :action, :page)
    indicator = active ? (descending ? :sort_desc : :sort_asc) : :sort_both

    link_to employees_path(query), class: "group inline-flex items-center gap-1 #{active ? 'text-gray-900' : 'hover:text-gray-700'}",
                                   aria: { sort: (active ? (descending ? "descending" : "ascending") : nil) } do
      safe_join([ label, icon(indicator, css: "size-3.5 #{active ? 'text-gray-700' : 'text-gray-300 group-hover:text-gray-400'}") ])
    end
  end
end
