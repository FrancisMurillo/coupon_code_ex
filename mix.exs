defmodule CouponCode.MixProject do
  use Mix.Project

  def project do
    [
      app: :coupon_code_ex,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      package: package(),
      name: "CouponCodeEx",
      source_url: "https://github.com/FrancisMurillo/coupon_code_ex",
      homepage_url: "https://github.com/FrancisMurillo/coupon_code_ex",
      docs: [
        main: "CouponCode",
        extras: ["README.md"]
      ]
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      description: "Generate and validate coupon codes in Elixir",
      maintainers: ["Francis Murillo"],
      licenses: ["GPLv3"],
      links: %{"GitHub" => "https://github.com/FrancisMurillo/coupon_code_ex"}
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:credo, "~> 1.3", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test}
    ]
  end
end
