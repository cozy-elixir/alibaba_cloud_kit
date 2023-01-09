defprotocol CozyAliyunOpenAPI.HTTPRequest.Transform do
  @doc """
  Converts a spec struct to an HTTP request struct.
  """
  def to_request(spec)
end
