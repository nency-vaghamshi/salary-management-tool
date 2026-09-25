namespace :db do
  desc "Seed payroll-ready employees up to a target count, e.g. bin/rails \"db:seed_employees[10000]\""
  task :seed_employees, [ :target_count ] => :environment do |_task, args|
    args.with_defaults(target_count: 10_000)

    # Integer() rather than to_i so "10k" or "abc" fails loudly instead of
    # quietly seeding 10 or skipping.
    target_count = Integer(args[:target_count], exception: false)
    abort "target_count must be a positive integer, got #{args[:target_count].inspect}" unless target_count&.positive?

    # Tops up instead of always inserting, so rerunning is safe.
    needed_count = target_count - Employee.count
    if needed_count <= 0
      puts "Already at #{target_count}+ employees, nothing to do."
      next
    end

    puts "Seeding #{needed_count} employees..."
    EmployeeDataSeeder.call(needed_count)
    puts "Seeded #{needed_count} employees (total: #{Employee.count})"
  rescue EmployeeDataSeeder::MissingReferenceDataError => e
    abort "#{e.message}. Run bin/rails db:seed first."
  end
end
