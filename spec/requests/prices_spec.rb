require "rails_helper"

RSpec.describe "Prices API", type: :request do
  describe "GET /prices/:symbol" do
    it "returns cached price when available" do
      CryptoPriceCache.write("btc", 100_000)

      get "/prices/btc"

      body = JSON.parse(response.body)

      expect(response).to have_http_status(:ok)
      expect(body["symbol"]).to eq("btc")
      expect(body["price"]).to eq(100_000)
      expect(body["currency"]).to eq("USD")
      expect(body["updated_at"]).to be_present
    end

    it "falls back to database when cache is missing" do
      CryptoPrice.create!(symbol: "btc", price: 100_000)

      Rails.cache.clear
      get "/prices/btc"
      body = JSON.parse(response.body)

      expect(response).to have_http_status(:ok)
      expect(body["symbol"]).to eq("btc")
      expect(body["price"].to_f).to eq(100_000.0)
      expect(body["currency"]).to eq("USD")
      expect(body["updated_at"]).to be_present
    end

    it "returns 404 when no price data exists" do
      Rails.cache.clear
      get "/prices/btc"

      body = JSON.parse(response.body)

      expect(response).to have_http_status(:not_found)
      expect(body["error"]).to eq("Price unavailable")
    end

    it "returns bad request for invalid symbol" do
      get "/prices/abc"
      body = JSON.parse(response.body)

      expect(response).to have_http_status(:bad_request)
      expect(body["error"]).to eq("Invalid symbol")
    end
  end
end
