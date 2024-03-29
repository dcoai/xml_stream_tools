defmodule XMLStreamTools.MixProject do
  use Mix.Project

  def project do
    [
      app: :xml_stream_tools,
      version: "0.1.0",
      elixir: "~> 1.15",
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:mix_test_watch, "~> 1.2", only: :dev, runtime: false},
      {:nimble_parsec, "~> 1.4"}
    ]
  end
end
