defmodule ExAliyunSls.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_aliyun_sls,
      version: "0.2.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [extras: ["README.md"]],
      description: "Aliyun Log Service log producer for Elixir",
      source_url: "https://github.com/edragonconnect/ex_aliyun_sls",
      package: package(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ExAliyunSls.Application, []},
      extra_applications: [:logger]
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{"Github" => "https://github.com/edragonconnect/ex_aliyun_sls"}
    ]
  end

  defp aliases do
    ["gen.pb": ["protox.generate --keep-unknown-fields=false --output-path=lib/ex_aliyun_sls/protobuf/log_logs.pb.ex protos/log_logs.proto"]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tesla, "~> 1.4"},
      {:finch, "~> 0.5"},
      {:plug, "~> 1.7"},
      {:protox, "~> 1.2"},
      {:jason, "~> 1.2"},
      {:timex, "~> 3.6"},
      {:elixir_uuid, "~> 1.2"},
      {:ex_doc, "~> 0.20", only: :dev, runtime: false},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end
end
