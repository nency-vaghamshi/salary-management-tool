require "rails_helper"

RSpec.describe ApplicationRecord do
  it "is the abstract base class, not backed by a table of its own" do
    expect(described_class).to be_abstract_class
  end

  it "is the base class every model inherits from" do
    expect(Employee.superclass).to eq(described_class)
  end
end
