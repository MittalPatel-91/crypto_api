# app/services/crypto_price_cache.rb

class CryptoPriceCache
  class << self
    def cache_key(symbol)
      "crypto_price:#{symbol.to_s.downcase}"
    end

    def write(symbol, price)
      Rails.cache.write(
        cache_key(symbol),
        { price: price, updated_at: Time.current }
      )
    end

    def read_price(symbol)
      Rails.cache.read(cache_key(symbol))
    end
  end
end
