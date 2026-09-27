require "rails_helper"

RSpec.describe SalaryRevisionService do
  let(:employment) { create(:employment, start_date: Date.new(2024, 1, 1)) }
  let(:currency) { create(:currency) }
  let(:basic) { create(:salary_component, calculation_type: "fixed") }
  let(:bonus) { create(:salary_component, calculation_type: "percentage") }

  def revise(effective_from: Date.new(2025, 1, 1), component_amounts: { basic => 80_000 }, on: employment)
    described_class.new(employment: on, currency: currency, effective_from: effective_from, component_amounts: component_amounts).call
  end

  it "creates an active, open-ended salary record with its components" do
    result = revise(component_amounts: { basic => 80_000, bonus => 8_000 })

    expect(result).to be_success
    expect(result.errors).to be_empty
    expect(result.salary_record).to have_attributes(employment: employment, currency: currency, status: "active",
                                                    effective_from: Date.new(2025, 1, 1), effective_to: nil)
    expect(result.salary_record.total_amount).to eq(88_000)
  end

  it "snapshots each component's calculation_type" do
    result = revise(component_amounts: { bonus => 8_000 })

    expect(result.salary_record.salary_record_components.sole.calculation_type).to eq("percentage")
  end

  it "closes the current record the day before the new one starts" do
    previous = revise(effective_from: Date.new(2024, 1, 1)).salary_record

    revise(effective_from: Date.new(2025, 1, 1))

    expect(previous.reload).to have_attributes(status: "inactive", effective_to: Date.new(2024, 12, 31))
    expect(employment.salary_records.active.count).to eq(1)
  end

  it "parses effective_from from a string, as forms send it" do
    expect(revise(effective_from: "2025-03-01").salary_record.effective_from).to eq(Date.new(2025, 3, 1))
  end

  it "saves a new employment together with an employee's first salary" do
    new_employment = build(:employment)

    expect { revise(on: new_employment) }.to change(Employment, :count).by(1)
    expect(new_employment).to be_persisted
  end

  it "rejects an empty set of components" do
    result = revise(component_amounts: {})

    expect(result).not_to be_success
    expect(result.errors).to eq([ "At least one salary component is required" ])
  end

  it "rejects an unparseable effective_from" do
    result = revise(effective_from: "not-a-date")

    expect(result).not_to be_success
    expect(result.errors).to eq([ "Effective from is not a valid date" ])
  end

  it "rejects a missing effective_from" do
    expect(revise(effective_from: nil).errors).to eq([ "Effective from is not a valid date" ])
  end

  context "when a record fails validation" do
    it "returns its errors and rolls back every change" do
      previous = revise(effective_from: Date.new(2025, 1, 1)).salary_record

      # Starting before the current record would close it before it opened.
      result = revise(effective_from: Date.new(2024, 6, 1))

      expect(result).not_to be_success
      expect(result.errors).to include("Effective to must be on or after the effective_from date")
      expect(previous.reload).to have_attributes(status: "active", effective_to: nil)
      expect(employment.salary_records.count).to eq(1)
    end

    it "does not leave an orphaned employment behind" do
      new_employment = build(:employment)

      expect { revise(on: new_employment, component_amounts: { basic => -1 }) }.not_to change(Employment, :count)
    end

    it "reports a negative component amount" do
      expect(revise(component_amounts: { basic => -1 }).errors).to include("Amount must be greater than or equal to 0")
    end
  end
end
