defmodule PlugSessionRedis.RubyEncoder do
  def encode(data) do
    {:ok, encode!(data)}
  end

  def decode(data) do
    try do
      {:ok, decode!(data)}
    rescue
      reason -> {:error, reason}
    end
  end

  def encode!(data) do
    ExMarshal.encode(data)
  end

  def decode!(data) do
    user_id = extract_user_id(data)
    %{"ra9api" => %{user_id: user_id}}
  end

  defp extract_user_id(data) do
    result = Regex.named_captures(~r/user_idi(?<user_id>.+):\x11session_type/, data)
    case result do
      nil ->
        nil
      true ->
        result["user_id"]
    end
  end

  # This code comes from ex_marshal.
  # See. https://github.com/eole-repos/ex_marshal/blob/master/lib/ex_marshal/decoder.ex#L47
  defp decode_fixnum(<<value::binary>>) do
    <<fixnum_type::8, fixnum_data::binary>> = value

    case fixnum_type do
      0 -> {0, fixnum_data}
      v when v >= 6 and v <= 127 ->
        <<fixnum::signed-little-integer-size(8)>> = <<v>>

        {fixnum - 5, fixnum_data}
      v when v >= 128 and v <= 250 ->
        <<fixnum::signed-little-integer-size(8)>> = <<v>>

        {fixnum + 5, fixnum_data}
      1 ->
        <<fixnum::8, rest::binary>> = fixnum_data

        {fixnum, rest}
      255 ->
        <<value::size(1)-bytes, rest::binary>> = fixnum_data
        <<fixnum::signed-little-integer-size(16)>> = <<value::binary, 255>>

        {fixnum, rest}
      2 ->
        <<value::size(2)-bytes, rest::binary>> = fixnum_data
        <<fixnum::little-integer-size(24)>> = <<value::binary, 0>>

        {fixnum, rest}
      254 ->
        <<value::size(2)-bytes, rest::binary>> = fixnum_data
        <<fixnum::signed-little-integer-size(24)>> = <<value::binary, 255>>

        {fixnum, rest}
      3 ->
        <<value::size(3)-bytes, rest::binary>> = fixnum_data
        <<fixnum::little-integer-size(32)>> = <<value::binary, 0>>

        {fixnum, rest}
      253 ->
        <<value::size(3)-bytes, rest::binary>> = fixnum_data
        <<fixnum::signed-little-integer-size(24)>> = <<value::binary>>

        {fixnum, rest}
      4 ->
        <<value::size(4)-bytes, rest::binary>> = fixnum_data
        <<fixnum::little-integer-size(32)>> = <<value::binary>>

        {fixnum, rest}
      252 ->
        <<value::size(4)-bytes, rest::binary>> = fixnum_data
        <<fixnum::signed-little-integer-size(32)>> = <<value::binary>>

        {fixnum, rest}
    end
  end
end
