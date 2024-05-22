defmodule CozyAliyunOpenAPI.HTTP.Client.Finch do
  @moduledoc """
  Finch-based HTTP client.

  In order to use `Finch` as the HTTP client, you must start `Finch` and
  provide a `:name`. Often in your supervision tree:

      children = [
        {Finch, name: CozyAliyunOpenAPI.Finch}
      ]

  Or, in rare cases, dynamically:

      Finch.start_link(name: CozyAliyunOpenAPI.Finch)

  If a name different from `CozyAliyunOpenAPI.Finch` is used, or you want to
  use an existing `Finch` instance, you can provide the name via the config:

      config :cozy_aliyun_open_api,
        finch_name: MyApp.Finch

  """

  require Logger
  alias CozyAliyunOpenAPI.HTTP.Request
  alias CozyAliyunOpenAPI.HTTP.Response

  @behaviour CozyAliyunOpenAPI.HTTP.Client

  @impl true
  def init do
    unless Code.ensure_loaded?(Finch) do
      Logger.error("""
      Could not find finch dependency.

      Please add :finch to your dependencies:

          {:finch, "~> 0.13"}

      Or set your own HTTP client:

          config :cozy_aliyun_open_api,
            http_client: MyHTTP.Client

      """)

      raise "missing finch dependency"
    end

    _ = Application.ensure_all_started(:finch)
    :ok
  end

  @impl true
  def request(%Request{} = req) do
    method = build_method(req)
    url = build_url(req)
    headers = build_headers(req)
    body = build_body(req)

    request = Finch.build(method, url, headers, body)

    case Finch.request(request, finch_name()) do
      {:ok, response} ->
        {:ok,
         struct(Response, status: response.status, headers: response.headers, body: response.body)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_method(req), do: req.method

  defp build_url(req) do
    query = encode_query(req.query)

    %URI{
      scheme: req.scheme,
      host: req.host,
      port: req.port,
      path: req.path,
      query: query
    }
    |> URI.to_string()
  end

  defp encode_query(query) when query == %{}, do: nil
  defp encode_query(query) when is_map(query), do: URI.encode_query(query)

  defp build_headers(req) do
    Enum.map(req.headers, fn {k, v} ->
      {to_string(k), to_string(v)}
    end)
  end

  defp build_body(req), do: req.body

  defp finch_name() do
    Application.get_env(:cozy_aliyun_open_api, :finch_name, CozyAliyunOpenAPI.Finch)
  end
end
