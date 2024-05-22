defprotocol CozyAliyunOpenAPI.HTTP.Request.Transform do
  @moduledoc """
  The protocol for transforming a spec to an `%HTTP.Request{}`.
  """

  @doc """
  Converts a spec struct to an HTTP request struct.
  """
  def to_request!(spec)
end
