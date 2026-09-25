Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]

  # Aktifkan breadcrumb dari ActiveRecord dan Net::HTTP
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Kirim 100% error; untuk performance monitoring, turunkan ke 0.1–0.5
  config.traces_sample_rate = 1.0

  # Sertakan environment agar mudah dibedakan di dashboard Sentry
  config.environment = Rails.env

  # Jangan kirim event di test/development untuk menghindari noise
  config.enabled_environments = %w[production staging]
end
