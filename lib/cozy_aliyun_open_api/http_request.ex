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
  @type scheme() :: String.t()

  @typedoc """
  Request host.
  """
  @type host() :: String.t()

  @typedoc """
  Request method.
  """
  @type method() :: String.t()

  @typedoc """
  Request path.
  """
  @type path() :: String.t()

  @typedoc """
  Optional request query.
  """
  @type query() :: %{
          optional(name :: String.t()) => value :: boolean() | number() | String.t()
        }

  @typedoc """
  Request headers.
  """
  @type headers() :: %{
          optional(name :: String.t()) => value :: String.t()
        }

  @typedoc """
  Optional request body.
  """
  @type body() :: iodata() | nil

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
  Creates a HTTP request struct.
  """
  def new!(%{} = args) do
    args
    |> as_struct!()
  end

  defp as_struct!(map) do
    default_struct = __MODULE__.__struct__()
    valid_keys = Map.keys(default_struct)
    map = Map.take(map, valid_keys)
    Map.merge(default_struct, map)
  end

  @doc """
  Parses an URL, then takes the scheme, host, port and path.
  """
  def parse_base_url(url) when is_binary(url) do
    url
    |> URI.parse()
    |> Map.take([:scheme, :host, :port, :path])
  end
end
