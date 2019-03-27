# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :ex_aliyun_sls, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:ex_aliyun_sls, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#

## You should config like below

# config :ex_aliyun_sls,
#  profile: %{
#    endpoint: "YOUR SLS ENDPOINT",
#    access_key_id: "YOUR ACCESS KEY ID",
#    access_key: "YOUR ACCESS KEY",
#    project: "YOUR SLS PROJECT NAME"
#  },
#  logstore: "YOUR LOG STORE NAME",
#  package_count: 100, # Default to 100
#  package_timeout: 10_000 # You can choose whether to set it
#  filtered_params: ["name", "card"] # Add your filtered params here

# config :logger,
#  backends: [
#    {ExAliyunSls.LoggerBackend, :sls}
#  ]
#
# config :logger, :sls, metadata: :all

import_config "#{Mix.env()}.exs"
