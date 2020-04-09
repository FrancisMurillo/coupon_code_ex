defmodule CouponCode.Parity.ValidateTest do
  @moduledoc """
  Taken from `03-validate.t` test from the Perl module, this tests that
  `CouponCode.validate/2` works fine.

  Source: https://metacpan.org/source/GRANTM/Algorithm-CouponCode-1.005/t/03-validate.t
  """

  use ExUnit.Case

  alias CouponCode

  test "validate should be work" do
    assert {:error, :parts_invalid, 0} = CouponCode.validate("")
    assert {:ok, "1K7Q-CTFM-LMTC"} = CouponCode.validate("1K7Q-CTFM-LMTC")
    assert {:error, :parts_invalid, 2} = CouponCode.validate("1K7Q-CTFM")

    assert {:ok, "1K7Q-CTFM"} = CouponCode.validate("1K7Q-CTFM", parts: 2)
    assert {:error, :part_invalid, 0} = CouponCode.validate("CTFM-1K7Q", parts: 2)

    assert {:ok, "1K7Q-CTFM-LMTC"} = CouponCode.validate("1k7q-ctfm-lmtc")
  end

  test "validate similar should work" do
    assert {:ok, "190D-V467-8D52"} = CouponCode.validate("I9oD-V467-8D52")
    assert {:ok, "190D-V467-8D52"} = CouponCode.validate("I9oD-V467-8D52")
    assert {:ok, "190D-V467-8D52"} = CouponCode.validate("i9oD-V467-8D52")
    assert {:ok, "190D-V467-8D52"} = CouponCode.validate("i9oD-V467-8D52")
    assert {:ok, "190D-V467-8D52"} = CouponCode.validate("i9oD-V467-8D5z")
    assert {:ok, "190D-V467-8D52"} = CouponCode.validate("i9oD-V467-8D5z")
    assert {:ok, "190D-V467-8D52"} = CouponCode.validate("i9oD-V467-8Dsz")
    assert {:ok, "190D-V467-8D52"} = CouponCode.validate("i9oD-V467-8Dsz")
  end

  test "validate separator should work" do
    assert {:ok, "190D-V467-8D52"} = CouponCode.validate("i9oD/V467/8Dsz")
    assert {:ok, "190D-V467-8D52"} = CouponCode.validate("i9oD V467 8Dsz")
    assert {:ok, "190D-V467-8D52"} = CouponCode.validate("i9oD_V467_8Dsz")
    assert {:ok, "190D-V467-8D52"} = CouponCode.validate("i9oDV4678Dsz")
  end

  test "validate checkdigit should work" do
    assert {:ok, "1K7Q"} = CouponCode.validate("1K7Q", parts: 1)
    assert {:error, :part_invalid, 0} = CouponCode.validate("1K7C", parts: 1)

    assert {:ok, "1K7Q-CTFM"} = CouponCode.validate("1K7Q-CTFM", parts: 2)
    assert {:error, :part_invalid, 1} = CouponCode.validate("1K7Q-CTFW", parts: 2)

    assert {:ok, "1K7Q-CTFM-LMTC"} = CouponCode.validate("1K7Q-CTFM-LMTC", parts: 3)
    assert {:error, :part_invalid, 2} = CouponCode.validate("1K7Q-CTFM-LMT1", parts: 3)

    assert {:ok, "7YQH-1FU7-E1HX-0BG9"} = CouponCode.validate("7YQH-1FU7-E1HX-0BG9", parts: 4)
    assert {:error, :part_invalid, 3} = CouponCode.validate("7YQH-1FU7-E1HX-0BGP", parts: 4)

    assert {:ok, "YENH-UPJK-PTE0-20U6-QYME"} =
             CouponCode.validate("YENH-UPJK-PTE0-20U6-QYME", parts: 5)

    assert {:error, :part_invalid, 4} = CouponCode.validate("YENH-UPJK-PTE0-20U6-QYMT", parts: 5)

    assert {:ok, "YENH-UPJK-PTE0-20U6-QYME-RBK1"} =
             CouponCode.validate("YENH-UPJK-PTE0-20U6-QYME-RBK1", parts: 6)

    assert {:error, :part_invalid, 5} =
             CouponCode.validate("YENH-UPJK-PTE0-20U6-QYME-RBK2", parts: 6)
  end
end
