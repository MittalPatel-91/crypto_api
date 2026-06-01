require "rails_helper"

RSpec.describe FetchCryptoPriceJob, type: :job do
  let(:client) { instance_double(CoingeckoClient) }

  before do
    allow(CoingeckoClient).to receive(:new).and_return(client)
  end

  describe "#perform" do
    context "when CoinGecko returns prices for all symbols" do
      let(:prices) do
        {
          "btc" => 100_000,
          "eth" => 3_000,
          "ltc" => 80,
          "doge" => 0.15
        }
      end

      before do
        allow(client).to receive(:fetch_prices)
          .with(CryptoPrice::SUPPORTED_SYMBOLS)
          .and_return(prices)
      end

      it "stores all fetched prices in the database" do
        described_class.perform_now

        prices.each do |symbol, price|
          record = CryptoPrice.find_by(symbol: symbol)
          expect(record).to be_present
          expect(record.price).to eq(price)
        end
      end

      it "writes all prices to cache" do
        described_class.perform_now

        prices.each do |symbol, price|
          cached_data = CryptoPriceCache.read_price(symbol)
          expect(cached_data[:price]).to eq(price)
        end
      end
    end

    context "when CoinGecko returns a partial response" do
      it "updates only symbols present in the response" do
        allow(client).to receive(:fetch_prices).and_return({ "btc" => 100_000 })

        described_class.perform_now

        expect(CryptoPrice.find_by(symbol: "btc").price).to eq(100_000)
        expect(CryptoPrice.find_by(symbol: "eth")).to be_nil
      end
    end

    context "when CoinGecko is unavailable" do
      it "keeps existing prices when the batch request fails" do
        record = CryptoPrice.create!(symbol: "btc", price: 90_000)

        allow(client).to receive(:fetch_prices).and_raise(Faraday::TimeoutError)
        described_class.perform_now

        expect(record.reload.price).to eq(90_000)
      end
    end
  end
end
