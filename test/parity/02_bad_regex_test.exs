defmodule CouponCode.Parity.BadRegexTest do
  @moduledoc """
  Taken from `02-bad-regex.t` test from the Perl module, this tests that
  `CouponCode.bad_word_regex/0` detects filtered words correctly.

  Source: https://metacpan.org/source/GRANTM/Algorithm-CouponCode-1.005/t/02-bad-words.t
  """

  use ExUnit.Case

  alias CouponCode

  setup do
    old_bad_words = Application.get_env(:coupon_code_ex, :bad_words)

    on_exit(fn ->
      :ok = Application.put_env(:coupon_code_ex, :bad_words, old_bad_words)
    end)

    :ok
  end

  test "sample bad words should be detected" do
    bad_regex = CouponCode.bad_word_regex()

    assert "P00P" =~ bad_regex
    refute "P00P1E" =~ bad_regex
    assert "POOP" =~ bad_regex
    assert "B00B" =~ bad_regex
  end

  test "added bad words should be detected" do
    old_bad_words = Application.get_env(:coupon_code_ex, :bad_words)

    on_exit(fn ->
      :ok = Application.put_env(:coupon_code_ex, :bad_words, old_bad_words)
    end)

    bad_words = Enum.map(["P00P", "FORD", "FIAT"], &CouponCode.rot13/1)
    :ok = Application.put_env(:coupon_code_ex, :bad_words, bad_words)

    ammended_bad_regex = CouponCode.bad_word_regex()

    assert "F0RD" =~ ammended_bad_regex
    assert "F1AT" =~ ammended_bad_regex
    assert "P00P" =~ ammended_bad_regex
  end

  test "replaced bad words should be detected" do
    bad_words = Enum.map(["FORD", "FIAT"], &CouponCode.rot13/1)
    :ok = Application.put_env(:coupon_code_ex, :bad_words, bad_words)

    replaced_bad_regex = CouponCode.bad_word_regex()

    assert "F0RD" =~ replaced_bad_regex
    assert "F1AT" =~ replaced_bad_regex
    refute "P00P" =~ replaced_bad_regex
  end

  test "bad word regex should be used by `CouponCode.generate/1`" do
    bad_words = Enum.map(["FORD", "FIAT"], &CouponCode.rot13/1)
    :ok = Application.put_env(:coupon_code_ex, :bad_words, bad_words)

    assert CouponCode.generate(plaintext: "2160") =~ ~r/AR5E/

    old_bad_words = Enum.map(["AR5E"], &CouponCode.rot13/1)
    :ok = Application.put_env(:coupon_code_ex, :bad_words, old_bad_words)

    refute CouponCode.generate(plaintext: "2160") =~ ~r/AR5E/

    ammended_bad_words = Enum.map(["FORD", "FIAT", "AR5E"], &CouponCode.rot13/1)
    :ok = Application.put_env(:coupon_code_ex, :bad_words, ammended_bad_words)

    refute CouponCode.generate(plaintext: "2160") =~ ~r/AR5E/
  end
end
