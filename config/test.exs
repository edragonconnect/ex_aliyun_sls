import Config

config :logger,
  backends: [
    {ExAliyunSls.LoggerBackend, :sls},
  ]

import_config "#{Mix.env()}.secret.exs"
