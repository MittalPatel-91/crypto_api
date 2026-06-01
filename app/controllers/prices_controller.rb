# app/controllers/prices_controller.rb

class PricesController < ApplicationController
  USD = "USD".freeze

  def show
    symbol = params[:symbol].downcase

    unless CryptoPrice::SUPPORTED_SYMBOLS.include?(symbol)
      return render json: { error: "Invalid symbol"  }, status: :bad_request
    end

    cached_data = CryptoPriceCache.read_price(symbol)

    if cached_data.present?
      return render json: {
        symbol: symbol, price: cached_data[:price], currency: USD, updated_at: cached_data[:updated_at]
      }
    end

    record = CryptoPrice.find_by(symbol: symbol)

    if record.present?
      render json: {
        symbol: symbol, price: record.price, currency: USD, updated_at: record.updated_at
      }
    else
      render json: {
        error: "Price unavailable"
      }, status: :not_found
    end
  end
end
