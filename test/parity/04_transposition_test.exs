defmodule CouponCode.Parity.TranspositionTest do
  @moduledoc """
  Taken from `04-transposition.t` test from the Perl module, this tests that
  `CouponCode.generate/1` prevents transposable codes.

  Source: https://metacpan.org/source/GRANTM/Algorithm-CouponCode-1.005/t/04-transposition.t
  """

  use ExUnit.Case

  alias CouponCode

  @sample_size 1_000

  test "generate should not have transposable codes" do
    Enum.each(1..@sample_size, fn _ ->
      code = CouponCode.generate(parts: 1)
      <<a, b, c, d>> = code

      assert {:ok, ^code} = CouponCode.validate(<<a, b, c, d>>, parts: 1)

      [<<b, a, c, d>>, <<a, c, b, d>>, <<a, b, d, c>>]
      |> Enum.reject(&(&1 == code))
      |> Enum.each(fn transposed_code ->
        assert {:error, :part_invalid, 0} = CouponCode.validate(transposed_code, parts: 1)
      end)
    end)
  end
end
