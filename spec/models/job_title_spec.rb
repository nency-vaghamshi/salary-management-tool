require "rails_helper"

RSpec.describe JobTitle, type: :model do
  it "is valid with a name and code" do
    job_title = JobTitle.new(name: "Software Engineer", code: "SWE")

    expect(job_title).to be_valid
  end

  it "is invalid without a name" do
    job_title = JobTitle.new(name: nil, code: "SWE")

    expect(job_title).not_to be_valid
    expect(job_title.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a code" do
    job_title = JobTitle.new(name: "Software Engineer", code: nil)

    expect(job_title).not_to be_valid
    expect(job_title.errors[:code]).to include("can't be blank")
  end

  it "is invalid with a duplicate code" do
    JobTitle.create!(name: "Software Engineer", code: "SWE")
    duplicate = JobTitle.new(name: "Senior Software Engineer", code: "SWE")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:code]).to include("has already been taken")
  end
end
