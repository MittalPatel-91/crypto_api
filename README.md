# Crypto API

A Rails API that fetches cryptocurrency prices from [CoinGecko](https://www.coingecko.com/), stores them in PostgreSQL and Redis, and serves the latest known price.

## Current functionality

### Price endpoint

A single read endpoint returns the price for **one symbol** at a time:

```
GET /prices/:symbol
```

| Case | Status | Response |
|------|--------|----------|
| Price in cache | `200` | `symbol`, `price`, `currency`, `updated_at` |
| Cache miss, price in DB | `200` | Same shape (DB `updated_at`) |
| No cached or stored price | `404` | `{ "error": "Price unavailable" }` |
| Unsupported symbol | `400` | `{ "error": "Invalid symbol" }` |

**Supported symbols (static):** `btc`, `eth`, `ltc`, `doge`

**Currency:** The assignment did not require a currency parameter, so all prices are fetched and returned in **USD** only. The API includes `"currency": "USD"` in successful responses for clarity.

**Example**

```bash
curl http://localhost:3000/prices/btc
```

```json
{
  "symbol": "btc",
  "price": 73504,
  "currency": "USD",
  "updated_at": "2026-06-01T16:00:00.000Z"
}
```

### Caching and fallback

1. **Read path:** Redis cache first, then PostgreSQL (last known price).
2. **Write path:** Background job updates DB and cache after each successful CoinGecko fetch.
3. **API failure:** If CoinGecko errors (rate limit, timeout, etc.), existing cache/DB values are left unchanged so clients still receive the last known price.

### Background job and scheduler

- **`FetchCryptoPriceJob`** runs on a schedule via **Sidekiq** + **sidekiq-cron**.
- One cron entry (`config/schedule.yml`) runs **every minute** and fetches all four supported symbols in a **single batch** HTTP request to CoinGecko (USD).
- Results are persisted to `crypto_prices` and written to Redis through `CryptoPriceCache`.

### Other behavior

- **Rate limiting:** [Rack::Attack](https://github.com/rack/rack-attack) throttles `/prices` requests (60 requests per IP per minute).
- **Health check:** `GET /up` (Rails default).

## Architecture (high level)

```
CoinGecko API
      │
      ▼ (every minute)
FetchCryptoPriceJob ──► PostgreSQL (crypto_prices)
      │                      ▲
      └──► Redis cache ──────┘ (read: cache → DB)
                ▲
                │
         GET /prices/:symbol
```

## Tech stack

- Ruby 3.4.8 / Rails 8.1
- PostgreSQL
- Redis (cache + Sidekiq)
- Sidekiq, sidekiq-cron
- Faraday (CoinGecko client)
- RSpec

## Prerequisites

- Ruby 3.4.8 (see `.ruby-version`)
- PostgreSQL
- Redis

## Setup

```bash
git clone <repo-url>
cd crypto_api
bundle install
cp database.example.yml database.yml
cp .env.example .env   # then add your CoinGecko credentials
bin/rails db:create db:migrate
```

### Environment variables

| Variable | Description |
|----------|-------------|
| `COINGECKO_API_KEY` | CoinGecko API key |
| `COINGECKO_BASE_URL` | CoinGecko API base URL (e.g. `https://api.coingecko.com/api/v3`) |
| `REDIS_URL` | Redis URL for Rails cache (default: `redis://localhost:6379/1`) |
| `SIDEKIQ_REDIS_URL` | Redis URL for Sidekiq (default: `redis://localhost:6379/0`) |

## Running locally

Start each process in its own terminal:

```bash
# API server
bin/rails server

# start redis server
redis-server

# Background workers + cron
bundle exec sidekiq
```

Ensure Redis and PostgreSQL are running before starting the app.

## Tests

```bash
bundle exec rspec
```

Covers job behavior (batch fetch, partial updates, API failure fallback), request specs (cache hit, DB fallback, errors), and model validations.

## Project layout (main pieces)

| Path | Purpose |
|------|---------|
| `app/controllers/prices_controller.rb` | Single-symbol price API |
| `app/jobs/fetch_crypto_price_job.rb` | Batch fetch and persist prices |
| `app/services/coingecko_client.rb` | CoinGecko HTTP client |
| `app/services/crypto_price_cache.rb` | Redis read/write helpers |
| `app/models/crypto_price.rb` | Supported symbols and validations |
| `config/schedule.yml` | Sidekiq-cron schedule |

---

## Future improvements

These are intentional extension points; they are **not** implemented yet.

### Multi-symbol, multi-currency API

Today only `GET /prices/:symbol` exists (one symbol, USD only). A natural next endpoint could accept:

- **Multiple symbols** — comma-separated (e.g. `btc,eth`)
- **Multiple currencies** — comma-separated, optional (e.g. `usd,eur`); default to USD when omitted

Example (illustrative):

```
GET /prices?symbols=btc,eth&currencies=usd,eur
```

Response could return a list of `{ symbol, currency, price, updated_at }` entries. This would require schema/cache key changes (e.g. composite keys like `crypto_price:btc:usd`).

### Dynamic symbols and currencies for the job

The cron job currently uses a **static** list: four symbols in USD, defined in `CryptoPrice::SUPPORTED_SYMBOLS` and `FetchCryptoPriceJob`.

This could be driven by configuration (YAML, ENV, or DB), for example:

```yaml
# illustrative
symbols: [btc, eth, ltc, doge]
currencies: [usd, eur]
```

The job would read that config, batch-fetch from CoinGecko per currency, and store each `(symbol, currency)` pair in cache and the database. The read API would then resolve prices using the same configuration or explicit request parameters.

### Other ideas

- Expose cache/DB staleness or `last_fetched_at` in API responses
- Metrics and alerting when CoinGecko failures exceed a threshold
- Admin endpoint to trigger a manual refresh
- Expand integration tests with VCR/WebMock against CoinGecko fixtures

## AI-assisted development

This project was built with help from multiple AI coding assistants in Cursor. See [docs/AI_ASSISTED_DEVELOPMENT.md](docs/AI_ASSISTED_DEVELOPMENT.md) for objectives, process, prompts, iterations, and manual verification steps.

