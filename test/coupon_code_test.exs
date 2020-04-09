defmodule CouponCodeTest do
  @moduledoc """
  Test cases for `CouponCode`
  """

  use ExUnit.Case

  alias CouponCode

  @characters "0123456789ABCDEFGHJKLMNPQRTUVWXY"
  @delimiter "-"

  @random_separators ["!", "@", "#", "$", "%", "^", "&", "*", "(", ")", " ", ""]

  describe "generate/1" do
    test "should work" do
      code = CouponCode.generate()

      assert code
      assert code =~ ~r/\w{4}-\w{4}-\w{4}/
      assert code =~ ~r/[0123456789ABCDEFGHJKLMNPQRTUVWXY-]+/
    end

    test "should work with args" do
      parts = random_parts()
      part_length = random_part_length()

      code = CouponCode.generate(parts: parts, part_length: part_length)

      pieces = String.split(code, @delimiter)

      assert parts == length(pieces)

      Enum.each(pieces, fn piece ->
        assert part_length == String.length(piece)
      end)
    end

    test "checkdigit should be correct " do
      parts = random_parts()
      part_length = random_part_length()

      code = CouponCode.generate(parts: parts, part_length: part_length)

      index_map =
        @characters
        |> :binary.bin_to_list()
        |> Enum.with_index()
        |> Enum.map(fn {character, index} ->
          {character, index}
        end)
        |> Enum.into(%{})

      code
      |> String.split(@delimiter)
      |> Enum.with_index()
      |> Enum.each(fn {piece, piece_index} ->
        {checkdigit, indices} =
          piece
          |> :binary.bin_to_list()
          |> Enum.map(&Map.fetch!(index_map, &1))
          |> List.pop_at(-1)

        assert checkdigit == Enum.reduce(indices, piece_index + 1, &rem(&2 * 19 + &1, 31))
      end)
    end

    test "static plaintext should generate the same code" do
      Enum.each(1..10, fn _ ->
        plaintext = random_plaintext()
        code = CouponCode.generate(plaintext: plaintext)

        Enum.each(1..5, fn _ ->
          assert code == CouponCode.generate(plaintext: plaintext)
        end)
      end)
    end

    test "should validate `plaintext` arg" do
      assert_raise ArgumentError, fn ->
        CouponCode.generate(plaintext: nil)
      end

      Enum.each(1..10, fn _ ->
        assert CouponCode.generate(plaintext: random_plaintext())
      end)
    end

    test "should validate `parts` args" do
      assert_raise ArgumentError, fn ->
        CouponCode.generate(parts: 0)
      end

      Enum.each(1..10, fn _ ->
        assert CouponCode.generate(parts: random_parts())
      end)
    end

    test "should validate `part_length` args" do
      assert_raise ArgumentError, fn ->
        CouponCode.generate(part_length: 1)
      end

      Enum.each(1..10, fn _ ->
        assert_raise ArgumentError, fn ->
          CouponCode.generate(part_length: 20 + :random.uniform(100))
        end

        assert CouponCode.generate(part_length: random_part_length())
      end)
    end
  end

  describe "validate/2" do
    test "should work" do
      code = CouponCode.generate()

      assert {:ok, ^code} = CouponCode.validate(code)
    end

    test "should work with args" do
      Enum.each(1..10, fn _ ->
        parts = random_parts()
        part_length = random_part_length()
        code = CouponCode.generate(parts: parts, part_length: part_length)

        assert {:ok, ^code} = CouponCode.validate(code, parts: parts, part_length: part_length)
      end)
    end

    test "should validate `parts` args" do
      code = CouponCode.generate()

      assert_raise ArgumentError, fn ->
        CouponCode.validate(code, parts: 0)
      end
    end

    test "should validate `part_length` args" do
      code = CouponCode.generate()

      assert_raise ArgumentError, fn ->
        CouponCode.validate(code, part_length: 1)
      end

      Enum.each(1..10, fn _ ->
        assert_raise ArgumentError, fn ->
          CouponCode.validate(code, part_length: 20 + :random.uniform(100))
        end
      end)
    end

    test "should detect invalid parts" do
      Enum.each(1..10, fn _ ->
        parts = random_parts()
        part_length = random_part_length()

        code = CouponCode.generate(parts: parts, part_length: part_length)

        assert {:error, :parts_invalid, _} =
                 CouponCode.validate(code,
                   parts: :random.uniform(parts - 1),
                   part_length: part_length
                 )

        assert {:error, :parts_invalid, _} =
                 CouponCode.validate(code,
                   parts: parts + :random.uniform(10),
                   part_length: part_length
                 )

        unless part_length == 2 do
          assert {:error, _, _} =
                   CouponCode.validate(code,
                     parts: parts,
                     part_length: max(:random.uniform(part_length - 1), 2)
                   )
        end

        unless part_length == 20 do
          assert {:error, _, _} =
                   CouponCode.validate(code,
                     parts: parts,
                     part_length: min(part_length + :random.uniform(10), 20)
                   )
        end

        Enum.each(1..3, fn _ ->
          assert {:error, :part_invalid, _} =
                   code
                   |> :binary.bin_to_list()
                   |> Enum.shuffle()
                   |> :binary.list_to_bin()
                   |> CouponCode.validate(parts: parts, part_length: part_length)
        end)
      end)
    end

    test "should detect invalid part checkdigits" do
      Enum.each(1..10, fn _ ->
        parts = random_parts()
        part_length = random_part_length()

        code = CouponCode.generate(parts: parts, part_length: part_length)

        pieces = String.split(code, @delimiter)

        pieces
        |> Enum.with_index()
        |> Enum.map(fn {piece, index} ->
          {base_piece, checkdigit} = String.split_at(piece, -1)
          other_characters = String.replace(@characters, checkdigit, "")

          other_characters
          |> :binary.bin_to_list()
          |> Enum.each(fn ch ->
            wrong_piece = base_piece <> <<ch>>

            assert {:error, :part_invalid, index} =
                     pieces
                     |> List.replace_at(index, wrong_piece)
                     |> Enum.join(@delimiter)
                     |> CouponCode.validate(parts: parts, part_length: part_length)
          end)
        end)

        Enum.each(1..10, fn _ ->
          assert {:error, :part_invalid, _} =
                   code
                   |> :binary.bin_to_list()
                   |> Enum.shuffle()
                   |> :binary.list_to_bin()
                   |> CouponCode.validate(parts: parts, part_length: part_length)
        end)
      end)
    end

    test "should validate with similar characters" do
      Enum.each(1..100, fn _ ->
        parts = random_parts()
        part_length = random_part_length()
        plaintext = random_plaintext()

        code = CouponCode.generate(parts: parts, part_length: part_length, plaintext: plaintext)

        assert {:ok, ^code} =
                 code
                 |> randomly_downcase_letters()
                 |> randomly_replace_separator()
                 |> randomly_replace_similar()
                 |> CouponCode.validate(parts: parts, part_length: part_length)
      end)
    end
  end

  describe "rot13/1" do
    test "should match samples" do
      assert "NOPQRSTUVWXYZABCDEFGHIJKLM" == CouponCode.rot13("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
      assert "nopqrstuvwxyzabcdefghijklm" == CouponCode.rot13("abcdefghijklmnopqrstuvwxyz")
      assert "1234567890!@#$%^&*()" == CouponCode.rot13("1234567890!@#$%^&*()")
      assert "Uryyb Jbeyq!" == CouponCode.rot13("Hello World!")
    end
  end

  describe "bad_word_regex/0" do
    test "should match samples" do
      assert "P00P" =~ CouponCode.bad_word_regex()
      assert "POOP" =~ CouponCode.bad_word_regex()
      refute "P00P1E" =~ CouponCode.bad_word_regex()
      refute "F0RD" =~ CouponCode.bad_word_regex()
    end
  end

  defp randomly_downcase_letters(text) do
    String.replace(text, ~r/[A-Z]/, fn letter ->
      if(random_boolean(), do: String.downcase(letter), else: letter)
    end)
  end

  defp randomly_replace_separator(text) do
    String.replace(text, @delimiter, fn separator ->
      if(random_boolean(), do: random_separator(), else: separator)
    end)
  end

  defp randomly_replace_similar(text) do
    [{"0", "O"}, {"1", "I"}, {"2", "Z"}, {"5", "S"}]
    |> Enum.reduce(text, fn {original, similar}, acc ->
      if(random_boolean(), do: String.replace(acc, original, similar), else: acc)
    end)
  end

  defp random_separator do
    Enum.random(@random_separators)
  end

  defp random_boolean do
    :random.uniform(2) == 2
  end

  defp random_parts do
    1 + :random.uniform(14)
  end

  defp random_part_length do
    2 + :random.uniform(18)
  end

  defp random_plaintext do
    :crypto.strong_rand_bytes(8)
  end
end
