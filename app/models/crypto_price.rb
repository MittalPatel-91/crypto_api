# app/models/crypto_price.rb

class CryptoPrice < ApplicationRecord
  # constant
  SUPPORTED_SYMBOLS = %w[ btc eth doge ltc ].freeze

  validates :symbol,
            presence: true,
            uniqueness: true,
            inclusion: { in: SUPPORTED_SYMBOLS }
end
