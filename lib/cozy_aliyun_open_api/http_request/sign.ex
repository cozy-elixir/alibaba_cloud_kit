defprotocol CozyAliyunOpenAPI.HTTPRequest.Sign do
  @moduledoc """
  The protocol for signing an HTTP request.
  """

  alias CozyAliyunOpenAPI.HTTPRequest

  @doc """
  Signs an HTTP request.
  """
  @spec sign(HTTPRequest.t(), map()) :: HTTPRequest.t()
  def sign(request, extra)
end
