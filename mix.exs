defmodule CozyAliyunOpenAPI.MixProject do
  use Mix.Project

  @version "0.2.0"
  @description "An SDK builder for Aliyun / Alibaba Cloud OpenAPI."
  @source_url "https://github.com/cozy-elixir/cozy_aliyun_open_api"

  def project do
    [
      app: :cozy_aliyun_open_api,
      version: @version,
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: @description,
      source_url: @source_url,
      homepage_url: @source_url,
      docs: docs(),
      package: package(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {CozyAliyunOpenAPI.Application, []},
      env: [json_library: Jason, http_client: CozyAliyunOpenAPI.HTTPClient.Finch]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support", "examples"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_options, "~> 1.0"},
      {:jason, "~> 1.0"},
      {:sax_map, "~> 1.0", optional: true},
      {:finch, "~> 0.13", only: [:dev, :test]},
      {:mox, "~> 1.0", only: [:test]},
      {:tesla, "~> 1.4", only: [:test]},
      {:ex_check, "~> 0.15.0", only: [:dev], runtime: false},
      {:credo, ">= 0.0.0", only: [:dev], runtime: false},
      {:dialyxir, ">= 0.0.0", only: [:dev], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev], runtime: false},
      {:mix_audit, ">= 0.0.0", only: [:dev], runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}"
    ]
  end

  defp package do
    [
      exclude_patterns: [],
      licenses: ["Apache-2.0"],
      links: %{GitHub: @source_url}
    ]
  end

  defp aliases do
    [publish: ["hex.publish", "tag"], tag: &tag_release/1]
  end

  defp tag_release(_) do
    Mix.shell().info("Tagging release as v#{@version}")
    System.cmd("git", ["tag", "v#{@version}"])
    System.cmd("git", ["push", "--tags"])
  end
end
