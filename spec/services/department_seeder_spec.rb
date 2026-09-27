require "rails_helper"

RSpec.describe DepartmentSeeder do
  describe ".call" do
    it "creates every department" do
      expect { described_class.call }.to change(Department, :count).by(described_class::DEPARTMENTS.size)

      expect(Department.find_by(code: "ENG").name).to eq("Engineering")
    end

    it "is idempotent" do
      described_class.call

      expect { described_class.call }.not_to change(Department, :count)
    end

    it "keeps a department that already exists as it is" do
      create(:department, code: "ENG", name: "Platform Engineering")

      described_class.call

      expect(Department.find_by(code: "ENG").name).to eq("Platform Engineering")
    end

    it "returns the seeded departments" do
      expect(described_class.call.map(&:code)).to eq(described_class::DEPARTMENTS.map { |d| d[:code] })
    end
  end
end
