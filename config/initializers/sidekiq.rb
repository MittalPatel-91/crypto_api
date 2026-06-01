Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("SIDEKIQ_REDIS_URL", "redis://localhost:6379/0") }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("SIDEKIQ_REDIS_URL", "redis://localhost:6379/0") }
end

Sidekiq::Cron::Job.load_from_hash YAML.load_file(
  Rails.root.join("config/schedule.yml")
)
