defmodule CouponCode do
  @moduledoc """
  A module for generating coupon codes in Elixir. Inspired by the Perl
  library [CouponCode](https://github.com/grantm/Algorithm-CouponCode),
  a coupon code is a group of letters and numbers known as `part` and
  separated by a hyphen(`-`) that is meant for a receipient types in. For
  example, a 3 part code with 4 characters per part looks like this:

    ```
    H6YV-UDPL-383N
    ```

  Like with the original module, it has the same features:

    * Codes are validated regardless of case (upper or lower)

    * Codes use the upper cased letters and numbers; however, it does
      not use the letters `"O"`, `"I"`, `"Z"` and `"S"` since they are visually
      similar to `"0"`, `"1"`, `"2"` and `"5"`. Still, the receipient can enter
      those ambigious letters and be considered valid or corrected.

    * The last character of every part is a checkdigit that helps in
      determining which specifc part(s) has been entered correctly.

    * Generated parts are also rejected against a list of bad words since
      they are manually entered.

    * Generated parts that can be transposed (or for example with a 4
      character part `ABCD`, the parts `BACD`. `ACBD` and `ABDC` generate a
      valid checkdigit) are also rejected.

  ## Config

  While this library has good defaults, it can be configured like so:

    ```elixir
    config :coupon_code_ex,
      parts: 3
      part_length: 4
      bad_words: ~w(SHPX PHAG JNAX JNAT CVFF PBPX FUVG GJNG GVGF SNEG URYY ZHSS QVPX XABO NEFR FUNT GBFF FYHG GHEQ FYNT PENC CBBC OHGG SRPX OBBO WVFZ WVMM CUNG)
    ```

  While `part_length` can have multiple values, it is discouraged to
  change it from the default since the `bad_words` is built for that
  length. If you still want to change it, remember to update the
  `bad_words` lists to the maximum length that is supported.

  When customizing the `bad_words` list, remember it is encoded with
  `rot13` to avoid profanity in the code or configuraton. So right
  before adding a new word to that list, you can encode it with
  `CouponCode.rot13/1` or an [online rot13 encoder](https://rot13.com/).
  """

  @characters "0123456789ABCDEFGHJKLMNPQRTUVWXY"
  @plaintext_size 8
  @parts 3
  @part_length 4
  @bad_words ~w(
    SHPX PHAG JNAX JNAT
    CVFF PBPX FUVG GJNG
    GVGF SNEG URYY ZHSS
    QVPX XABO NEFR FUNT
    GBFF FYHG GHEQ FYNT
    PENC CBBC OHGG SRPX
    OBBO WVFZ WVMM CUNG
  )
  @delimiter "-"

  @doc """
  Generate the regex used in detecting bad words from the generated codes.

  Aside from detecting all words in the decoded list, it should detect
  similar characters (`0` to `O`, `1` to `I`, `2` to `S` and `5` to `Z`).

  ## Examples

    ```elixir
    iex> "P00P" =~ CouponCode.bad_word_regex()
    true

    iex> "POOP" =~ CouponCode.bad_word_regex()
    true

    iex> "P00P1E" =~ CouponCode.bad_word_regex()
    false

    iex> "F0RD" =~ CouponCode.bad_word_regex()
    false
    ```

  """
  @spec bad_word_regex() :: Regex.t()
  def bad_word_regex do
    get_bad_words()
    |> generate_bad_word_regex()
  end

  defp generate_bad_word_regex(bad_words) do
    bad_words
    |> Enum.map(fn bad_word ->
      bad_word
      |> String.upcase()
      |> String.replace(~r/[^0-9A-Z]+/, "")
      |> String.replace(~r/[0O]/, "[0O]")
      |> String.replace(~r/[I1]/, "[I1]")
      |> String.replace(~r/[Z2]/, "[Z2]")
      |> String.replace(~r/[S5]/, "[S5]")
      |> (&"\\b#{&1}\\b").()
    end)
    |> Enum.join("|")
    |> Regex.compile!()
  end

  @doc """
  Generate a random coupon code.

  ## Algorithm

  Like with the original module, each generated code uses a `plaintext`
  as a source of bytes. It is then hashed with `sha1` and consumed for
  each random character that is needed (which excludes checkdigits) to
  generate a part. When the bytes are insufficient to generate a new
  part or is rejected by having a filtered word or is transposable, it
  is rehashed to generate and used as the new source of bytes. This
  process is repeated until every part is generated.

  ## Options

  This function takes a keyword options as the first argument:

    * `plaintext` - The plaintext to use for generating the coupon code.
      Useful in generating the same or deterministic code with the same
      options but usually not filled in. If none is given, a random 8
      byte plaintext is generated.

    * `parts` - The number of delimited segments to generate. Defaults
      to #{@parts} or `Application.get_env(:coupon_code_ex, :parts)` and
      must be a positive integer.

    * `part_length` - The number of characters per each part which
      includes the checkdigit. Defaults to #{@part_length} or
      `Application.get_env(:coupon_code_ex, :part_length)` and must be a
      positive integer between 2 - 20 inclusively. (The limitation stems
      from `sha1` generating exactly 20 bytes.)


  ## Examples

    ```elixir
    iex> CouponCode.generate(plaintext: "1234567890")
    "1K7Q-CTFM-LMTC"

    iex> CouponCode.generate(plaintext: "123456789A")
    "X730-KCV1-MA2G"

    iex> CouponCode.generate()
    "5UMN-WBKJ-2MCA"

    iex> CouponCode.generate(parts: 1)
    "YUVN"

    iex> CouponCode.generate(parts: 5)
    "D51P-H52K-9VMD-UT5H-XE3A"

    iex> CouponCode.generate(part_length: 3)
    "GVB-KDB-ADF"

    iex> CouponCode.generate(part: 2, part_length: 7)
    "86NMUDX-GFEJHVR"
    ```

  """
  @spec generate(Keyword.t()) :: charlist
  def generate(opts \\ []) do
    plaintext = get_plaintext(opts)
    parts = get_parts(opts)
    part_length = get_part_length(opts)

    code_parts =
      do_generate(
        sha1(plaintext),
        parts,
        part_length,
        String.split(@characters, "", trim: true),
        bad_word_regex(),
        []
      )

    code_parts
    |> Enum.reverse()
    |> Enum.join(@delimiter)
  end

  defp do_generate(_bytes, 0, _part_length, _characters, _bad_regex, acc),
    do: acc

  defp do_generate(bytes, parts, part_length, characters, bad_regex, acc)
       when byte_size(bytes) < part_length - 1 do
    do_generate(sha1(bytes), parts, part_length, characters, bad_regex, acc)
  end

  defp do_generate(bytes, parts, part_length, characters, bad_regex, acc) do
    base_indices =
      bytes
      |> binary_part(0, part_length - 1)
      |> :binary.bin_to_list()
      |> Enum.map(&rem(&1, 32))

    part = length(acc) + 1
    check_index = part_checkdigit(base_indices, part)

    new_part_indices = List.insert_at(base_indices, -1, check_index)

    new_part =
      new_part_indices
      |> Enum.map(&Enum.at(characters, &1))
      |> Enum.join("")

    has_bad_word = String.match?(new_part, bad_regex)
    can_transpose = transposable?(new_part_indices, part)

    if has_bad_word or can_transpose do
      do_generate(sha1(bytes), parts, part_length, characters, bad_regex, acc)
    else
      next_bytes = binary_part(bytes, part_length - 1, byte_size(bytes) - part_length + 1)

      do_generate(next_bytes, parts - 1, part_length, characters, bad_regex, [new_part | acc])
    end
  end

  defp transposable?(indices, code) do
    indices
    |> Stream.with_index()
    |> Stream.chunk_every(2, 1, :discard)
    |> Enum.any?(fn [{left_index, pos}, {right_index, _}] ->
      {transposed_checkdigit, transposed_indices} =
        indices
        |> List.replace_at(pos, right_index)
        |> List.replace_at(pos + 1, left_index)
        |> List.pop_at(-1)

      part_checkdigit(transposed_indices, code) == transposed_checkdigit
    end)
  end

  defp part_checkdigit(indices, code) do
    Enum.reduce(indices, code, &rem(&2 * 19 + &1, 31))
  end

  @doc """
  Validates a receipient entered code based on the required parts and
  length it should have.

  With an entered code, it is normalized with the following steps:

    * It is uppercased
    * All non-word (`0-9A-Z`) characters are removed
    * Similar letters (`OIZS`) are corrected (`0125`)

  If the normalized code is valid, this returns `{:ok, corrected_code}`.
  If the number of computed parts are invalid, it returns `{:error,
  :parts_invalid, actual_parts}`. Lastly it returns `{:error,
  :part_invalid, part_with_error}` for the first parsed part that has an
  checkdigit error.

  ## Options

  This function takes a keyword options as the second argument:

    * `parts` - The number of expected delimited segments to generate. Defaults
      to #{@parts} or `Application.get_env(:coupon_code_ex, :parts)` and
      must be a positive integer.

    * `part_length` - The number of expected characters per each part. Defaults to #{@part_length} or
      `Application.get_env(:coupon_code_ex, :part_length)` and must be a
      positive integer between 2 - 20 inclusively.

  ## Examples

    ```elixir
    iex> CouponCode.validate("7B5M-LJ4J-D5FN")
    {:ok, "7B5M-LJ4J-D5FN"}

    iex> CouponCode.validate("7B5MLJ4JD5FN")
    {:ok, "7B5M-LJ4J-D5FN"}

    iex> CouponCode.validate("7B5mlJ4jd5fn")
    {:ok, "7B5M-LJ4J-D5FN"}

    iex> CouponCode.validate("7B5mlJ4jd5fn", parts: 4)
    {:error, :parts_invalid, 3}

    iex> CouponCode.validate("7B5mlJ4jd5fn", part_length: 5)
    {:error, :parts_invalid, 2}

    iex> CouponCode.validate("7B5mlJ4jd5fM")
    {:error, :part_invalid, 2}

    iex> CouponCode.validate("i9oD-V467-8Dsz")
    {:ok, "190D-V467-8D52"}
    ```

  """
  @spec validate(charlist, Keyword.t()) ::
          {:ok, charlist}
          | {:error, :parts_invalid, pos_integer}
          | {:error, :part_invalid, pos_integer}
  def validate(code, opts \\ []) do
    parts = get_parts(opts)
    part_length = get_part_length(opts)

    parsed_parts =
      code
      |> String.upcase()
      |> String.replace(~r/[^0-9A-Z]+/, "")
      |> String.replace("O", "0")
      |> String.replace("I", "1")
      |> String.replace("Z", "2")
      |> String.replace("S", "5")
      |> :binary.bin_to_list()
      |> Enum.chunk_every(part_length, part_length, :discard)

    if length(parsed_parts) == parts do
      index_map =
        @characters
        |> to_charlist()
        |> Stream.with_index()
        |> Stream.map(fn {character, index} ->
          {character, index}
        end)
        |> Enum.into(%{})

      parsed_parts
      |> Stream.map(fn parsed_part ->
        Enum.map(parsed_part, &Map.fetch!(index_map, &1))
      end)
      |> Stream.with_index()
      |> Enum.reduce_while(:ok, fn {parsed_indices, part_index}, _acc ->
        {checkdigit, indices} = List.pop_at(parsed_indices, -1)

        if part_checkdigit(indices, part_index + 1) == checkdigit do
          {:cont, :ok}
        else
          {:halt, {:error, part_index}}
        end
      end)
      |> case do
        :ok ->
          {:ok, Enum.join(parsed_parts, @delimiter)}

        {:error, part_index} ->
          {:error, :part_invalid, part_index}
      end
    else
      {:error, :parts_invalid, length(parsed_parts)}
    end
  end

  @doc """
  [rot13](https://en.wikipedia.org/wiki/ROT13) utility function to encode/decode bad words.

  This encoding is a character substitution algorithm by rotating a
  letter 13 places after it. Lower case characters are equally converted
  while anything else is passedthrough.

  ## Examples

    ```elixir
    iex> CouponCode.rot13("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    "NOPQRSTUVWXYZABCDEFGHIJKLM"

    iex> CouponCode.rot13("abcdefghijklmnopqrstuvwxyz")
    "nopqrstuvwxyzabcdefghijklm"

    iex> CouponCode.rot13("1234567890!@#$%^&*()")
    "1234567890!@#$%^&*()"

    iex> CouponCode.rot13("Hello World!")
    "Uryyb Jbeyq!"
    ```

  """
  @spec rot13(charlist) :: charlist
  def rot13(text) do
    text
    |> to_charlist()
    |> Enum.map(fn ch ->
      cond do
        ch > ?z -> ch
        ch >= ?n -> ch - 13
        ch >= ?a -> ch + 13
        ch > ?Z -> ch
        ch >= ?N -> ch - 13
        ch >= ?A -> ch + 13
        true -> ch
      end
    end)
    |> to_string()
  end

  defp get_plaintext(opts) do
    plaintext = Keyword.get_lazy(opts, :plaintext, fn -> random_plaintext(@plaintext_size) end)

    unless is_binary(plaintext) do
      raise ArgumentError, "`plaintext` must be a binary: #{inspect(plaintext)}"
    end

    plaintext
  end

  defp get_bad_words do
    encoded_bad_words = Application.get_env(:coupon_code_ex, :bad_words) || @bad_words

    unless is_list(encoded_bad_words) and
             Enum.all?(encoded_bad_words, &String.match?(&1, ~r/[0-9A-Z]+/)) do
      raise ArgumentError,
            "`bad_words` must be a list with only upper case letters and numbers: #{
              inspect(encoded_bad_words)
            }"
    end

    Enum.map(encoded_bad_words, &rot13/1)
  end

  defp get_parts(opts) do
    parts =
      Keyword.get_lazy(opts, :parts, fn ->
        Application.get_env(:coupon_code_ex, :parts) || @parts
      end)

    unless is_integer(parts) and parts > 0 do
      raise ArgumentError, "`parts` must be a positive integer: #{inspect(parts)}"
    end

    parts
  end

  defp get_part_length(opts) do
    part_length =
      Keyword.get_lazy(opts, :part_length, fn ->
        Application.get_env(:coupon_code_ex, :parts) || @part_length
      end)

    unless is_integer(part_length) and part_length >= 2 and part_length <= 20 do
      raise ArgumentError,
            "`part_length` must be a positive integer within 2 and 20 inclusively: #{
              inspect(part_length)
            }"
    end

    part_length
  end

  defp random_plaintext(size) do
    :crypto.strong_rand_bytes(size)
  end

  defp sha1(text) do
    :crypto.hash(:sha, text)
  end
end
