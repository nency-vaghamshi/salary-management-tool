# Seeding is orchestration only: every dataset is built by a dedicated service
# in app/services so it can be reused (e.g. from a console or rake task) and
# each step stays idempotent on rerun.

DepartmentSeeder.call
JobTitleSeeder.call
SalaryComponentSeeder.call
hr_user = HrUserSeeder.call

# Countries, currencies and tax brackets come from the external tax API, so
# only fetch them once; a partial failure is reported but doesn't abort seeding.
if Country.none?
  result = TaxDataImporter.new.call
  puts "Tax import failed for: #{result.failed.map { |f| f[:code] }.join(', ')}" if result.failed.any?
end

puts <<~SUMMARY
  Departments:       #{Department.count}
  Job titles:        #{JobTitle.count}
  Salary components: #{SalaryComponent.count}
  Countries:         #{Country.count}
  Employees:         #{Employee.count}
  HR login:          #{hr_user.email}
SUMMARY
