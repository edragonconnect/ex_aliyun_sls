defmodule ExAliyunSls.MixProject do
  use Mix.Project

  @source_url "https://github.com/edragonconnect/ex_aliyun_sls"
  @version "0.4.0"

  def project do
    [
      app: :ex_aliyun_sls,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      aliases: aliases()
    ]
  end

  def application do
    [
      mod: {ExAliyunSls.Application, []},
      extra_applications: [:logger]
    ]
  end

  def package do
    [
      description: "Aliyun Log Service log producer for Elixir",
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp aliases do
    [
      "gen.pb": [
        "protox.generate --output-path=lib/ex_aliyun_sls/protobuf/log_logs.pb.ex protos/log_logs.proto"
      ]
    ]
  end

  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:finch, "~> 0.5"},
      {:plug, "~> 1.11"},
      {:protox, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:uniq, "~> 0.6"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      extras: [
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      formatters: ["html"]
    ]
  end
end
