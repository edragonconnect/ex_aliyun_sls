defmodule ExAliyunSls.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_aliyun_sls,
      version: "0.1.1",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :exprotobuf]
      # mod: {ExAliyunSls.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:exprotobuf, "~> 1.2"},
      {:tesla, "~> 1.2", optional: true},
      {:jason, "~> 1.1"},
      {:hackney, "~> 1.15"},
      {:timex, "~> 3.4"},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},
      {:plug, "~> 1.7"},
      {:elixir_uuid, "~> 1.2"}
    ]
  end
end
