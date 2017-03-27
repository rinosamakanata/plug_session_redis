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
    ExMarshal.decode(data)
  end
end
