# app/jobs/fetch_crypto_price_job.rb

class FetchCryptoPriceJob < ApplicationJob
  queue_as :default

  def perform(symbols = CryptoPrice::SUPPORTED_SYMBOLS)
    prices = CoingeckoClient.new.fetch_prices(symbols)

    prices.each do |symbol, price|
      persist_price(symbol, price)
    end

  rescue CoingeckoClient::RateLimitError => e
    Rails.logger.warn(e.message)

  rescue CoingeckoClient::ApiError => e
    Rails.logger.error("CoinGecko API error: #{e.message}")

  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
    Rails.logger.error("CoinGecko unavailable: #{e.message}")
  end

  private

  def persist_price(symbol, price)
    CryptoPrice.find_or_initialize_by(symbol: symbol)
               .update!(price: price)

    CryptoPriceCache.write(symbol, price)
  rescue => e
    Rails.logger.error("Failed to persist #{symbol}: #{e.message}")
  end
end
