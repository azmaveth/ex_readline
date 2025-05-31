defmodule ExReadline.MixProject do
  use Mix.Project

  @version "0.2.1"
  @github_url "https://github.com/azmaveth/ex_readline"

  def project do
    [
      app: :ex_readline,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      source_url: @github_url,
      homepage_url: @github_url
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
      {:ex_doc, "~> 0.36", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    A pure Elixir readline implementation with history, keybindings, and tab completion.
    Provides both simple and advanced line editing capabilities for CLI applications.
    """
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @github_url},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"],
      source_ref: "v#{@version}",
      groups_for_modules: [
        "Core Modules": [ExReadline, ExReadline.SimpleReader],
        "Advanced Features": [ExReadline.LineEditor, ExReadline.History, ExReadline.Keybindings],
        "Utilities": [ExReadline.Terminal]
      ]
    ]
  end
end