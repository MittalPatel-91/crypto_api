# AI-Assisted Development Summary

## Objective

Build a Rails API that:

* Fetches cryptocurrency prices from CoinGecko
* Refreshes prices every minute using a background job
* Serves cached prices via `/prices/:symbol`
* Falls back to the last known price when the external API is unavailable
* Includes automated tests for job logic, caching, and fallback behavior

## How AI Was Used

AI was used as a development assistant to:

* Propose application architecture
* Review implementation decisions
* Identify edge cases
* Suggest testing strategies
* Improve error handling and caching behavior

All code and design decisions were reviewed and adjusted manually before implementation.

## Development Process

### 1. Architecture Design

AI suggested:

* Rails API-only application
* Sidekiq for background jobs
* Redis for caching
* Service object for CoinGecko integration

These recommendations were adopted as they aligned with common Rails production practices.

### 2. CoinGecko Integration

AI helped design a dedicated `CoingeckoClient` with:

* Faraday HTTP client
* API key support
* Request timeouts
* Custom error handling

Additional improvements were made to handle malformed JSON responses and API failures gracefully.

### 3. Caching Strategy

Initial discussions explored cache expiration policies.

After reviewing the requirement to serve the last known price during outages, the final decision was to refresh the cache every minute via the background job and avoid cache expiration to preserve historical data during external API failures.

### 4. API Design

AI initially suggested supporting multiple symbols in a single request.

After reviewing the requirements, the implementation was simplified to support a single symbol endpoint:

```text
GET /prices/:symbol
```

to remain aligned with the assignment specification.

### 5. Error Handling & Fallbacks

AI-assisted reviews helped identify and address:

* Invalid symbol handling
* API timeouts and rate limits
* Cache misses
* Missing database records
* Cold-start scenarios

The final implementation returns meaningful error responses instead of returning null values.

### 6. Testing

AI helped identify test scenarios for:

* Background job execution
* Cache reads/writes
* Database fallback behavior
* Invalid symbol requests
* Missing data scenarios

## Outcome

AI accelerated implementation, design validation, and test coverage planning while all final architectural decisions, code refinements, and requirement interpretations were made manually.
