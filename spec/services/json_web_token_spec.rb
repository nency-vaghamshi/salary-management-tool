require "rails_helper"

RSpec.describe JsonWebToken do
  describe ".encode / .decode" do
    it "round-trips the payload with symbol keys" do
      token = described_class.encode({ user_id: 42 })

      expect(described_class.decode(token)).to include(user_id: 42)
    end

    it "expires tokens after 24 hours by default" do
      freeze_time do
        token = described_class.encode({ user_id: 42 })

        expect(described_class.decode(token)[:exp]).to eq(24.hours.from_now.to_i)
      end
    end

    it "honours a custom expiry" do
      freeze_time do
        token = described_class.encode({ user_id: 42 }, exp: 1.hour.from_now)

        expect(described_class.decode(token)[:exp]).to eq(1.hour.from_now.to_i)
      end
    end

    it "rejects an expired token" do
      token = described_class.encode({ user_id: 42 }, exp: 1.second.ago)

      expect { described_class.decode(token) }.to raise_error(JWT::ExpiredSignature)
    end

    it "rejects a token signed with a different secret" do
      forged = JWT.encode({ user_id: 42, exp: 1.hour.from_now.to_i }, "not-the-secret", "HS256")

      expect { described_class.decode(forged) }.to raise_error(JWT::VerificationError)
    end

    it "rejects a token that is not a JWT" do
      expect { described_class.decode("garbage") }.to raise_error(JWT::DecodeError)
    end

    it "rejects an unsigned token, so the algorithm can't be downgraded to none" do
      unsigned = JWT.encode({ user_id: 42, exp: 1.hour.from_now.to_i }, nil, "none")

      expect { described_class.decode(unsigned) }.to raise_error(JWT::DecodeError)
    end
  end
end
