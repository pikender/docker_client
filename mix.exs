defmodule DockerClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :docker_client,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../_config/config.exs",
      deps_path: "../../_deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:poison, ">= 3.1.0", override: true},
      {:tesla, "~> 0.8.0"},
      {:util, in_umbrella: true}
    ]
  end
end
