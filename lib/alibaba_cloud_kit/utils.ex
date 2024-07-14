defmodule AlibabaCloudKit.Utils do
  @moduledoc false

  @doc false
  def random_string() do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  @doc false
  # https://github.com/elixir-lang/elixir/blob/0a7881ff4b0b71b1fdca2b6332c5ff77188adc3c/lib/elixir/lib/uri.ex#L147
  def encode_rfc3986(string) when is_binary(string) do
    URI.encode(string, &URI.char_unreserved?/1)
  end

  @doc false
  def hmac_sha256(key, data) do
    :crypto.mac(:hmac, :sha256, key, data)
  end

  @doc false
  def hmac_sha1(key, data) do
    :crypto.mac(:hmac, :sha, key, data)
  end

  @doc false
  def sha256(data) do
    :crypto.hash(:sha256, data)
  end

  @doc false
  def md5(data) do
    :crypto.hash(:md5, data)
  end

  @doc false
  def base16(data) do
    Base.encode16(data, case: :lower)
  end

  @doc false
  def base64(data) do
    Base.encode64(data)
  end

  # JSON

  @doc false
  def encode_json!(term) do
    {:ok, binary} = JXON.encode(term)
    binary
  end

  @doc false
  def decode_json!(binary) do
    {:ok, term} = JXON.decode(binary)
    term
  end

  # Time

  @type time_unit :: :native | :microsecond | :millisecond | :second

  @spec utc_now(time_unit()) :: DateTime.t()
  def utc_now(time_unit), do: DateTime.utc_now(time_unit)

  @spec utc_today() :: Date.t()
  def utc_today(), do: Date.utc_today()

  @spec to_rfc1123(DateTime.t()) :: String.t()
  def to_rfc1123(date_time),
    do: Calendar.strftime(date_time, "%a, %d %b %Y %H:%M:%S GMT")

  @spec to_basic_iso8601(DateTime.t() | Date.t()) :: String.t()

  def to_basic_iso8601(%DateTime{} = date_time), do: DateTime.to_iso8601(date_time, :basic)

  def to_basic_iso8601(%Date{} = date), do: Date.to_iso8601(date, :basic)

  @spec to_extended_iso8601(DateTime.t() | Date.t()) :: String.t()
  def to_extended_iso8601(%DateTime{} = date_time), do: DateTime.to_iso8601(date_time, :extended)

  def to_extended_iso8601(%Date{} = date), do: Date.to_iso8601(date, :extended)
end
