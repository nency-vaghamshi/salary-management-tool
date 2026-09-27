require "rails_helper"

RSpec.describe Current do
  after { described_class.reset }

  it "holds the signed-in user for the current request" do
    user = build_stubbed(:user)

    described_class.user = user

    expect(described_class.user).to eq(user)
  end

  it "forgets the user once the request is reset, so it never leaks between requests" do
    described_class.user = build_stubbed(:user)

    described_class.reset

    expect(described_class.user).to be_nil
  end
end
