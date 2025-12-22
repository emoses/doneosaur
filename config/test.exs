import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :doneosaur, Doneosaur.Repo,
  database: "priv/repo/doneosaur_test#{System.get_env("MIX_TEST_PARTITION")}.db",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Use UTC timezone for tests to match test datetime fixtures
config :doneosaur, timezone: "Etc/UTC"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :doneosaur, DoneosaurWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "w+pdWD+33eMD1m5JQdWYdxbPz9vFP5z4zu23rm1EwxEYKdai4cq16lL8ACP0uzqB",
  server: false

# In test we don't send emails
config :doneosaur, Doneosaur.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
