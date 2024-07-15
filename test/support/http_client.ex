defmodule HTTPClient do
  def send_request(url) when is_binary(url) do
    Tesla.get(url)
  end

  def send_request(%HTTPSpec.Request{} = request) do
    Tesla.request(
      method: request.method,
      url: HTTPSpec.Request.build_url(request),
      headers: request.headers,
      body: request.body
    )
  end
end
