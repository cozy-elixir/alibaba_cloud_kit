defprotocol CozyAliyunOpenAPI.HTTPRequest.Transform do
  @moduledoc """
  The protocol for transforming a spec to an HTTP request.
  """

  @doc """
  Converts a spec struct to an HTTP request struct.
  """
  def to_request!(spec)
end
