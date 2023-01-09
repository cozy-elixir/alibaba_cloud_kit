defmodule CozyAliyunOpenAPI.MixProject do
  use Mix.Project

  def project do
    [
      app: :cozy_aliyun_open_api,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {CozyAliyunOpenAPI.Application, []},
      env: [http_client: CozyAliyunOpenAPI.HTTPClient.Finch]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:finch, "~> 0.13", only: [:dev, :test]}
    ]
  end
end
