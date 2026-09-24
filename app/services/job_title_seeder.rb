class JobTitleSeeder
  JOB_TITLES = [
    { name: "Software Engineer I", code: "SWE1" },
    { name: "Software Engineer II", code: "SWE2" },
    { name: "Senior Software Engineer", code: "SSWE" },
    { name: "Engineering Manager", code: "EM" },
    { name: "Sales Executive", code: "SALEX" },
    { name: "Account Manager", code: "ACCM" },
    { name: "Marketing Specialist", code: "MKTSP" },
    { name: "Financial Analyst", code: "FINAN" },
    { name: "HR Business Partner", code: "HRBP" },
    { name: "Operations Manager", code: "OPSM" },
    { name: "Product Manager", code: "PM" },
    { name: "Support Specialist", code: "SUPSP" }
  ].freeze

  def self.call
    new.call
  end

  def call
    JOB_TITLES.map do |attributes|
      JobTitle.find_or_create_by!(code: attributes[:code]) do |job_title|
        job_title.name = attributes[:name]
      end
    end
  end
end
