defmodule CozyAliyunOpenAPI.MixProject do
  use Mix.Project

  @version "0.1.1"
  @description "An SDK builder for Aliyun OpenAPI."
  @source_url "https://github.com/cozy-elixir/cozy_aliyun_open_api"

  def project do
    [
      app: :cozy_aliyun_open_api,
      version: @version,
      elixir: "~> 1.13",
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.0"},
      {:sax_map, "~> 1.0", optional: true},
      {:finch, "~> 0.13", only: [:dev, :test]},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_url: @source_url,
      source_ref: @version
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
    Mix.shell().info("Tagging release as #{@version}")
    System.cmd("git", ["tag", @version])
    System.cmd("git", ["push", "--tags"])
  end
end
