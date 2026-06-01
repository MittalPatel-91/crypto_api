# app/services/coingecko_client.rb

require "faraday"
require "json"

class CoingeckoClient
  class ApiError < StandardError; end
  class RateLimitError < ApiError; end

  def initialize
    @connection = Faraday.new(
      url: ENV.fetch("COINGECKO_BASE_URL"),
      headers: {
        "x-cg-demo-api-key" => ENV.fetch("COINGECKO_API_KEY")
      },
      request: {
        timeout: 5,
        open_timeout: 2
      }
    )
  end

  def fetch_prices(symbols)
    symbol_list = Array(symbols).map(&:to_s)
    return {} if symbol_list.empty?

    response = @connection.get(
      "simple/price",
      symbols: symbol_list.join(","),
      vs_currencies: "usd"
    )

    case response.status
    when 200
      parse_prices(response, symbol_list)
    when 429
      raise RateLimitError, "CoinGecko rate limit exceeded"
    else
      raise ApiError, "CoinGecko returned #{response.status}"
    end

  rescue JSON::ParserError => e
    Rails.logger.error("Invalid CoinGecko response: #{e.message}")

    raise ApiError, "Invalid response from CoinGecko"
  end

  def fetch_price(symbol)
    fetch_prices([ symbol ])[symbol.to_s]
  end

  private

  def parse_prices(response, symbols)
    body = JSON.parse(response.body)

    symbols.each_with_object({}) do |symbol, prices|
      price = body.dig(symbol, "usd")
      prices[symbol] = price if price.present?
    end
  end
end
