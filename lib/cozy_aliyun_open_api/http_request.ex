defmodule CozyAliyunOpenAPI.HTTPRequest do
  @moduledoc """
  A struct representing an HTTP request.
  """

  @enforce_keys [
    :scheme,
    :host,
    :port,
    :method,
    :path,
    :query,
    :headers,
    :body
  ]

  defstruct scheme: nil,
            host: nil,
            port: nil,
            method: nil,
            path: "/",
            query: %{},
            headers: %{},
            body: nil

  @typedoc """
  Request scheme.
  """
  @type scheme :: String.t()

  @typedoc """
  Request host.
  """
  @type host :: String.t()

  @typedoc """
  Request method.
  """
  @type method :: String.t()

  @typedoc """
  Request path.
  """
  @type path :: String.t()

  @typedoc """
  Optional request query.
  """
  @type query :: %{
          optional(name :: String.t()) => value :: boolean() | number() | String.t()
        }

  @typedoc """
  Request headers.
  """
  @type headers :: %{
          optional(name :: String.t()) => value :: String.t()
        }

  @typedoc """
  Optional request body.
  """
  @type body :: iodata() | nil

  @type t :: %__MODULE__{
          scheme: scheme(),
          host: host(),
          port: :inet.port_number(),
          method: method(),
          path: path(),
          query: query(),
          headers: headers(),
          body: body()
        }

  @doc """
  Creates an HTTP request struct.
  """
  def new!(%{} = args) do
    default_struct = __MODULE__.__struct__()
    valid_keys = Map.keys(default_struct)
    args = Map.take(args, valid_keys)
    Map.merge(default_struct, args)
  end

  @doc """
  Gets the url string of an HTTP request struct.
  """
  def url(%__MODULE__{} = request) do
    %URI{
      scheme: request.scheme,
      host: request.host,
      port: request.port,
      path: request.path,
      query: encode_query(request.query)
    }
    |> URI.to_string()
  end

  defp encode_query(query) when query == %{}, do: nil
  defp encode_query(query) when is_map(query), do: URI.encode_query(query)

  @doc """
  Creates an HTTP request struct from spec.
  """
  def from_spec!(spec) do
    __MODULE__.Transform.to_request!(spec)
  end

  def put_query(%__MODULE__{} = request, name, fun)
      when is_binary(name) and is_function(fun, 1) do
    value = apply(fun, [request])
    new_query = Map.put(request.query, name, value)
    %{request | query: new_query}
  end

  def put_query(%__MODULE__{} = request, name, value)
      when is_binary(name) do
    new_query = Map.put(request.query, name, value)
    %{request | query: new_query}
  end

  def put_new_query(%__MODULE__{} = request, name, fun)
      when is_binary(name) and is_function(fun, 1) do
    name = String.downcase(name)
    new_query = Map.put_new_lazy(request.query, name, fn -> apply(fun, [request]) end)
    %{request | query: new_query}
  end

  def put_header(%__MODULE__{} = request, name, fun)
      when is_binary(name) and is_function(fun, 1) do
    name = String.downcase(name)
    value = apply(fun, [request])
    new_headers = Map.put(request.headers, name, value)
    %{request | headers: new_headers}
  end

  def put_header(%__MODULE__{} = request, name, value)
      when is_binary(name) do
    name = String.downcase(name)
    new_headers = Map.put(request.headers, name, value)
    %{request | headers: new_headers}
  end

  def put_new_header(%__MODULE__{} = request, name, fun)
      when is_binary(name) and is_function(fun, 1) do
    name = String.downcase(name)
    new_headers = Map.put_new_lazy(request.headers, name, fn -> apply(fun, [request]) end)
    %{request | headers: new_headers}
  end

  def put_body(%__MODULE__{} = request, value) do
    %{request | body: value}
  end
end
