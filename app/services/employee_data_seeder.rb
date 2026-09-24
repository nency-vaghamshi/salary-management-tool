# Generates realistic employee records for local development and manual QA.
# Full-scale (10k) seeding is a later phase of the project plan; this is sized
# for exercising the Employee CRUD screens now.
class EmployeeDataSeeder
  def self.call(count)
    new(count).call
  end

  def initialize(count)
    @count = count
  end

  def call
    departments = Department.all.to_a
    job_titles = JobTitle.all.to_a
    countries = Country.all.to_a
    next_number = next_employee_number

    Faker::UniqueGenerator.clear

    @count.times do |i|
      first_name = Faker::Name.unique.first_name
      last_name = Faker::Name.unique.last_name

      Employee.create!(
        employee_number: format("EMP-%04d", next_number + i),
        first_name: first_name,
        last_name: last_name,
        email: Faker::Internet.unique.email(name: "#{first_name} #{last_name}"),
        department: departments.sample,
        job_title: job_titles.sample,
        nationality_country: countries.sample,
        residence_country: countries.sample
      )
    end
  end

  private

  def next_employee_number
    last_number = Employee.maximum(:employee_number)&.delete_prefix("EMP-")&.to_i || 0
    last_number + 1
  end
end
