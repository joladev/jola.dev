import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :jola_dev, JolaDevWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "qrif0xjEW0n+CC46Llt0xM33knCUvX0vxy2Gf53YfngjwMUmPojl/wu1+r71t1Aa",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Enable dev routes for dashboard and mailbox
config :jola_dev, dev_routes: true
