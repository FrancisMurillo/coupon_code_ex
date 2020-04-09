# CouponCodeEx
![BuildStatus](https://github.com/FrancisMurillo/coupon_code_ex/workflows/.github/workflows/elixir.yml/badge.svg)[![Coverage
Status](https://coveralls.io/repos/github/FrancisMurillo/coupon_code_ex/badge.svg?branch=poc)](https://coveralls.io/github/FrancisMurillo/coupon_code_ex?branch=master)[![Hex
pm](http://img.shields.io/hexpm/v/coupon_code_ex.svg?style=flat)](https://hex.pm/packages/coupon_code_ex)![GitHub](https://img.shields.io/github/license/FrancisMurillo/coupon_code_ex)

Generate and verify coupon codes in Elixir.

This library aims to be compatible with
[Algorithm-CouponCode](https://metacpan.org/pod/release/GRANTM/Algorithm-CouponCode-1.005/lib/Algorithm/CouponCode.pm)
and its tests including the major features such as:

- Similar character correction
- Undersirable code filter for bad and transposable parts
- Plaintext generation

## Installation

Add `:coupon_code_ex` to your project's `mix.exs`:

```elixir
def deps do
  [
    {:coupon_code_ex, "~> 0.1.0"}
  ]
end
```

## Usage

This library is primarily about two functions: `CouponCode.generate/1`
and `CouponCode.validate/2`. It is primarily used like this:

```elixir
# Generate a coupon code
CouponCode.generate()
"207Q-DVTV-K4EW"

CouponCode.generate(parts: 4)
"73F3-LMHT-T9JL-WT8W"

CouponCode.generate(parts: 2, part_length: 5)
"HMUCQ-2U12D"


# Static plaintext codes
CouponCode.generate(plaintext: "1234567890")
"1K7Q-CTFM-LMTC"


# Validate a code
CouponCode.validate("7B5M-LJ4J-D5FN")
{:ok, "7B5M-LJ4J-D5FN"}

CouponCode.validate("7B5X-LJ4X-D5FX")
{:error, :part_invalid, 0}

CouponCode.validate("7B5M-LJ4J-D5FN", parts: 2)
{:error, :parts_invalid, 3}

CouponCode.validate("7B5M-LJ4J-D5FN", parts: 2, part_length: 6)
{:error, :part_invalid, 0}


# Validate similar codes
CouponCode.validate("I9oD-V467-8D52")
{:ok, "190D-V467-8D52"}

CouponCode.validate("i9oD-V467-8Dsz")
{:ok, "190D-V467-8D52"}

CouponCode.validate("i9oDV4678Dsz")
{:ok, "190D-V467-8D52"}
```

Checkout the [HexDocs](https://hexdocs.pm/coupon_code_ex) for a more
detailed documentation including the bad word list and default configs.
