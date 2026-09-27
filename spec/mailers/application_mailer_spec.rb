require "rails_helper"

# ApplicationMailer only sets defaults, so it's exercised through a minimal
# subclass, the way every real mailer uses it.
RSpec.describe ApplicationMailer do
  let(:mailer_class) do
    Class.new(described_class) do
      def self.name = "ExampleMailer"

      def greeting
        mail(to: "grace@example.com", subject: "Hello") do |format|
          format.html { render html: "<p>Welcome aboard</p>".html_safe, layout: "mailer" }
        end
      end
    end
  end

  let(:mail) { mailer_class.greeting }

  it "sends from the default address" do
    expect(mail.from).to eq([ "from@example.com" ])
  end

  it "wraps the body in the shared mailer layout" do
    expect(mail.body.encoded).to include("<!DOCTYPE html>", "<p>Welcome aboard</p>")
  end
end
