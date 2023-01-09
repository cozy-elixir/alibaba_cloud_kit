defmodule CozyAliyunOpenAPI.Specs.Utils do
  @moduledoc false

  @doc false
  def random_string() do
    :crypto.strong_rand_bytes(24) |> Base.encode64(padding: false)
  end

  @doc false
  def iso8601_utc_now() do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end
end
