use Mix.Config

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :asciinema, AsciinemaWeb.Endpoint,
  http: [port: 4000],
  url: [scheme: "https", host: "asciinema.org", port: 443],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: "."

# Do not print debug messages in production
config :logger, level: :info

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :asciinema, AsciinemaWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :asciinema, AsciinemaWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

config :asciinema, Asciinema.Repo,
  pool_size: 20,
  ssl: false

config :asciinema, Asciinema.Emails.Mailer,
  deliver_later_strategy: Asciinema.BambooExqStrategy,
  adapter: Bamboo.SMTPAdapter,
  server: "smtp",
  port: 25
