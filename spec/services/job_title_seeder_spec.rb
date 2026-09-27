require "rails_helper"

RSpec.describe JobTitleSeeder do
  describe ".call" do
    it "creates every job title" do
      expect { described_class.call }.to change(JobTitle, :count).by(described_class::JOB_TITLES.size)

      expect(JobTitle.find_by(code: "PM").name).to eq("Product Manager")
    end

    it "is idempotent" do
      described_class.call

      expect { described_class.call }.not_to change(JobTitle, :count)
    end

    it "keeps a job title that already exists as it is" do
      create(:job_title, code: "PM", name: "Principal PM")

      described_class.call

      expect(JobTitle.find_by(code: "PM").name).to eq("Principal PM")
    end
  end
end
