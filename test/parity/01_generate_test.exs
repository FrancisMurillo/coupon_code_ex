defmodule CouponCode.Parity.GenerateTest do
  @moduledoc """
  Taken from `01-generate.t` test from the Perl module, this tests that
  `CouponCode.generate/1` works as expected.

  Source: https://metacpan.org/source/GRANTM/Algorithm-CouponCode-1.005/t/01-generate.t
  """

  use ExUnit.Case

  alias CouponCode

  test "static sample plaintext codes should match" do
    assert "1K7Q-CTFM-LMTC" == CouponCode.generate(plaintext: "1234567890")
    assert "X730-KCV1-MA2G" == CouponCode.generate(plaintext: "123456789A")
  end

  test "static plaintext should generate the same codes" do
    plaintext = "1234567890"
    assert CouponCode.generate(plaintext: plaintext) == CouponCode.generate(plaintext: plaintext)
  end

  test "random plaintext should generate different codes" do
    refute CouponCode.generate() == CouponCode.generate()
  end

  test "randomly generated codes should have the correct format" do
    code = CouponCode.generate()

    assert code =~ ~r/^[0-9A-Z-]+/
    assert code =~ ~r/^\w{4}-\w{4}-\w{4}+/
  end
end
