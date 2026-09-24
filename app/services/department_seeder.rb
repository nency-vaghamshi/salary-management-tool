class DepartmentSeeder
  DEPARTMENTS = [
    { name: "Engineering", code: "ENG" },
    { name: "Sales", code: "SAL" },
    { name: "Marketing", code: "MKT" },
    { name: "Finance", code: "FIN" },
    { name: "Human Resources", code: "HR" },
    { name: "Operations", code: "OPS" },
    { name: "Legal", code: "LEG" },
    { name: "Product", code: "PRD" },
    { name: "Customer Support", code: "SUP" },
    { name: "Information Technology", code: "IT" }
  ].freeze

  def self.call
    new.call
  end

  def call
    DEPARTMENTS.map do |attributes|
      Department.find_or_create_by!(code: attributes[:code]) do |department|
        department.name = attributes[:name]
      end
    end
  end
end
