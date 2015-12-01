defmodule Frank.Mixfile do
  use Mix.Project

  @version "0.0.3"

  def project do
    [app: :frank,
     version: @version,
     elixir: "~> 1.1",
     description: description,
     package: package,
     source_url: "https://github.com/triptec/frank",
     deps: deps]
  end

  def application do
    [applications: [:logger, :amqp]]
  end

  defp deps do
    [
      {:amqp, "0.1.4"},
      {:credo, "~> 0.1.9", only: [:dev, :test]},
      {:flaky_connection, git: "https://github.com/hamiltop/flaky_connection.git", only: :test},
    ]
  end

  defp description do
    """
    Simple Elixir client for RabbitMQ built on top of AMQP.
    """
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
     maintainers: ["Andreas Franzén"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/triptec/frank"}]
  end
end
