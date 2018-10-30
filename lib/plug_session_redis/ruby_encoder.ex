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
    encoded_user_id = extract_user_id(data)
    {decoded_user_id, _} = decode_fixnum(encoded_user_id)
    %{"ra9api" => %{user_id: decoded_user_id}}
  end

  defp extract_user_id(data) do
    result = Regex.named_captures(~r/user_idi(?<fixnum_type>.{1})/, data)
    read_byte_count = get_read_bytes_count(result["fixnum_type"])
    result = Regex.named_captures(~r/user_idi(?<user_id>.{#{read_byte_count}})/s, data)
    case result do
      nil ->
        nil
      _ ->
        result["user_id"]
    end
  end

  defp get_read_bytes_count(<<value::binary>>) do
    <<fixnum_type::8, fixnum_data::binary>> = value
    case fixnum_type do
      v when v >= 1 and v <= 4 ->
        v + 1
      v when v >= 252 and v <= 255 ->
        256 - v + 1
      _ ->
        1
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
