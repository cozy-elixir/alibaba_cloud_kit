defmodule CozyAliyunOpenAPI.Specs.RPC do
  @moduledoc """
  Describes an RPC style API.

  Read more at
  [阿里云SDK > 调用机制 > RPC 调用机制](https://help.aliyun.com/document_detail/315526.html).

  ## Examples

      alias CozyAliyunOpenAPI.Config
      alias CozyAliyunOpenAPI.Specs.RPC

      config =
        Config.new!(%{
          access_key_id: "...",
          access_key_secret: "..."
        })

      RPC.new!(config, %{
        method: :post,
        endpoint: "https://example.com/",
        shared_params: %{
          "Action" => "SingleSendMail",
          "Version" => "2015-11-23",
          # ...
        },
        params: %{
          "AccountName" => "...",
          # ...
        }
      })

  """

  alias CozyAliyunOpenAPI.Config
  alias CozyAliyunOpenAPI.Specs.Utils

  @enforce_keys [
    :method,
    :endpoint,
    :shared_params,
    :params
  ]
  defstruct method: nil,
            endpoint: nil,
            shared_params: %{},
            params: %{}

  @type method() :: :get | :post
  @type endpoint() :: String.t()
  @type shared_params() :: %{
          optional(name :: String.t()) => value :: boolean() | number() | String.t()
        }
  @type params() ::
          %{
            optional(name :: String.t()) => value :: boolean() | number() | String.t()
          }
          | nil

  @type spec_config() :: %{
          method: method(),
          endpoint: endpoint(),
          shared_params: shared_params(),
          params: params()
        }

  @type t :: %__MODULE__{
          method: method(),
          endpoint: endpoint(),
          shared_params: shared_params(),
          params: params()
        }

  @spec new!(Config.t(), spec_config()) :: t()
  def new!(%Config{} = config, %{} = spec_config) do
    spec_config
    |> validate_method!()
    |> validate_endpoint!()
    |> as_struct!()
    |> put_shared_params!(config)
    |> put_signature(config)
  end

  @valid_methods [:get, :post]
  defp validate_method!(%{method: method} = spec_config) when method in @valid_methods do
    spec_config
  end

  defp validate_method!(_spec_config) do
    raise ArgumentError, "key :method should be one of #{inspect(@valid_methods)}"
  end

  defp validate_endpoint!(%{endpoint: endpoint} = spec_config) when is_binary(endpoint) do
    spec_config
  end

  defp validate_endpoint!(_spec_config) do
    raise ArgumentError, "key :endpoint should be provided"
  end

  defp as_struct!(spec_config) do
    default_struct = __MODULE__.__struct__()
    valid_keys = Map.keys(default_struct)
    spec_config = Map.take(spec_config, valid_keys)
    Map.merge(default_struct, spec_config)
  end

  # Action
  # Version
  defp put_shared_params!(%__MODULE__{} = spec, %Config{} = config) do
    Map.update!(spec, :shared_params, fn shared_params ->
      shared_params
      |> Map.put_new_lazy("Format", fn -> "JSON" end)
      |> Map.put_new_lazy("Timestamp", fn -> Utils.iso8601_utc_now() end)
      |> Map.put_new_lazy("SignatureNonce", fn -> Utils.random_string() end)
      |> Map.put("AccessKeyId", config.access_key_id)
      |> Map.put("SignatureMethod", "HMAC-SHA1")
      |> Map.put("SignatureVersion", "1.0")
    end)
  end

  defp put_signature(%__MODULE__{} = spec, %Config{} = config) do
    %{
      method: method,
      shared_params: shared_params,
      params: params
    } = spec

    all_params = Map.merge(shared_params, params)

    signature =
      string_to_sign({method, all_params})
      |> sign(config.access_key_secret)

    Map.update!(spec, :shared_params, fn shared_params ->
      Map.put(shared_params, "Signature", signature)
    end)
  end

  defp sign(string_to_sign, secret) do
    string_to_sign
    |> then(&:crypto.mac(:hmac, :sha, "#{secret}&", &1))
    |> Base.encode64()
  end

  defp string_to_sign({method, params}) do
    [
      upcase_method(method),
      "/",
      encode_params(params)
    ]
    |> Enum.map(&rfc3986_encode/1)
    |> Enum.join("&")
  end

  defp upcase_method(method) when is_atom(method) do
    method
    |> to_string()
    |> String.upcase()
  end

  defp encode_params(params) when is_map(params) do
    params
    |> Enum.sort()
    |> Enum.map(fn {k, v} -> rfc3986_encode(k) <> "=" <> rfc3986_encode(v) end)
    |> Enum.join("&")
  end

  # https://github.com/elixir-lang/elixir/blob/0a7881ff4b0b71b1fdca2b6332c5ff77188adc3c/lib/elixir/lib/uri.ex#L147
  defp rfc3986_encode(string) do
    URI.encode(to_string(string), &URI.char_unreserved?/1)
  end
end

alias CozyAliyunOpenAPI.Specs.RPC
alias CozyAliyunOpenAPI.HTTPRequest

defimpl HTTPRequest.Transform, for: RPC do
  def to_request(%RPC{method: :get = method} = rpc) do
    %{
      endpoint: endpoint,
      shared_params: shared_params,
      params: params
    } = rpc

    %{scheme: scheme, host: host, port: port} = HTTPRequest.parse_base_url(endpoint)

    HTTPRequest.new!(%{
      scheme: scheme,
      host: host,
      port: port,
      method: method,
      path: "/",
      query: Map.merge(shared_params, params),
      body: nil
    })
  end

  def to_request(%RPC{method: :post = method} = rpc) do
    %{
      endpoint: endpoint,
      shared_params: shared_params,
      params: params
    } = rpc

    %{scheme: scheme, host: host, port: port} = HTTPRequest.parse_base_url(endpoint)

    HTTPRequest.new!(%{
      scheme: scheme,
      host: host,
      port: port,
      method: method,
      path: "/",
      query: shared_params,
      body: params
    })
  end
end
