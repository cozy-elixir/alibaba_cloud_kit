defmodule AlibabaCloudKit.Utils do
  @moduledoc false

  @doc false
  def random_string() do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end

  @doc false
  def parse_base_url(url) when is_binary(url) do
    url
    |> URI.parse()
    |> Map.take([:scheme, :host, :port, :path])
  end

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

  @doc false
  # https://github.com/elixir-lang/elixir/blob/0a7881ff4b0b71b1fdca2b6332c5ff77188adc3c/lib/elixir/lib/uri.ex#L147
  def encode_rfc3986(term) when not is_list(term) do
    URI.encode(to_string(term), &URI.char_unreserved?/1)
  end

  @doc false
  def hmac_sha256(key, data) do
    :crypto.mac(:hmac, :sha256, key, data)
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
end
