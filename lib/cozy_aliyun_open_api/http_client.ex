defmodule CozyAliyunOpenAPI.HTTPClient do
  @moduledoc """
  The specification for a HTTP client.

  It can be set to a client provided by `CozyAliyunOpenAPI`, such as:

      config :cozy_aliyun_open_api,
        http_client: CozyAliyunOpenAPI.HTTPClient.Finch

  Or, set it to your own API client, such as:

      config :cozy_aliyun_open_api,
        http_client: MyHTTPClient

  """

  alias CozyAliyunOpenAPI.HTTPRequest
  alias __MODULE__.Format

  @type status :: pos_integer()
  @type headers :: [{binary(), binary()}]
  @type body :: map() | binary()

  @typedoc """
  The response of a request.
  """
  @type response() :: {:ok, status, headers, body} | {:error, term()}

  @doc """
  Callback to initialize the given API client.
  """
  @callback init() :: :ok

  @doc """
  Callback to send a request.
  """
  @callback request(HTTPRequest.t()) :: response()

  @optional_callbacks init: 0

  @doc false
  def init do
    client = http_client()

    if Code.ensure_loaded?(client) and function_exported?(client, :init, 0) do
      :ok = client.init()
    end

    :ok
  end

  @doc """
  Issues an HTTP request by the given HTTP client.

  When the `content-type` header of the response is `"application/xml"` or
  `"text/xml"`, this function will try to convert the XML body to a map
  with snaked-cased keys.

  When the `content-type` header of the response is `"application/json"`,
  this function will try to convert the body to a map with snaked-cased
  keys.
  """
  @spec request(HTTPRequest.t()) :: response()
  def request(%HTTPRequest{} = req) do
    req
    |> http_client().request()
    |> maybe_to_map()
  end

  defp maybe_to_map({:ok, status, headers, body} = response) do
    case List.keyfind(headers, "content-type", 0) do
      {"content-type", "application/xml" <> _} ->
        {:ok, status, headers, body |> Format.convert_xml_to_map!()}

      {"content-type", "text/xml" <> _} ->
        {:ok, status, headers, body |> Format.convert_xml_to_map!()}

      {"content-type", "application/json" <> _} ->
        {:ok, status, headers, body |> Format.convert_json_to_map!()}

      _ ->
        response
    end
  end

  defp maybe_to_map(response), do: response

  defp http_client do
    Application.fetch_env!(:cozy_aliyun_open_api, :http_client)
  end
end
