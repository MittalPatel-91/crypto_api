# spec/models/crypto_price_spec.rb

require "rails_helper"

RSpec.describe CryptoPrice, type: :model do
  subject { described_class.create(symbol: "btc", price: 100_000) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:symbol) }

    it do
      is_expected.to validate_inclusion_of(:symbol)
        .in_array(CryptoPrice::SUPPORTED_SYMBOLS)
    end

    it { is_expected.to validate_uniqueness_of(:symbol) }
  end

  describe "validations" do
    it "is valid with a supported symbol" do
      crypto_price = described_class.new(
        symbol: "btc",
        price: 100_000
      )

      expect(crypto_price).to be_valid
    end

    it "is invalid without a symbol" do
      crypto_price = described_class.new(
        price: 100_000
      )

      expect(crypto_price).not_to be_valid
      expect(crypto_price.errors[:symbol]).to include("can't be blank")
    end

    it "is invalid with an unsupported symbol" do
      crypto_price = described_class.new(
        symbol: "abc",
        price: 100_000
      )

      expect(crypto_price).not_to be_valid
      expect(crypto_price.errors[:symbol]).to include("is not included in the list")
    end

    it "enforces symbol uniqueness" do
      described_class.create!(
        symbol: "btc",
        price: 100_000
      )

      duplicate = described_class.new(
        symbol: "btc",
        price: 110_000
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:symbol]).to include("has already been taken")
    end
  end
end
