defmodule ExAliyunSls.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_aliyun_sls,
      version: "0.2.0",
      elixir: "~> 1.6",
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
    [gen_pb: ["cmd protoc -I protos --elixir_out=lib/ex_aliyun_sls/protobuf protos/*.proto"]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.20", only: :dev, runtime: false},
      {:protobuf, "~> 0.7.1"},
      {:tesla, "~> 1.3", optional: true},
      {:jason, "~> 1.2"},
      {:hackney, "~> 1.15"},
      {:timex, "~> 3.6"},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:plug, "~> 1.7"},
      {:elixir_uuid, "~> 1.2"}
    ]
  end
end
