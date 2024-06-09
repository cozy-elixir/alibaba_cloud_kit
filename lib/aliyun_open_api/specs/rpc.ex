defmodule AliyunOpenAPI.Specs.RPC do
  @moduledoc """
  Describes an RPC style API.

  APIs in the RPC style include:

    * Elastic Compute Service (ECS)
    * Content Delivery Network (CDN)
    * ApsaraDB RDS
    * ...

  ## Examples

      alias AliyunOpenAPI.Config
      alias AliyunOpenAPI.Specs.RPC

      config =
        Config.new!(
          access_key_id: "...",
          access_key_secret: "..."
        )

      RPC.new!(config,
        endpoint: "https://ecs-cn-hangzhou.aliyuncs.com/",
        method: :post,
        version: "2015-11-23",
        action: "DescribeInstanceStatus",
        params: %{
          "RegionId" => "cn-hangzhou"
        }
      )

  """

  alias AliyunOpenAPI.Config

  @spec_opts_schema [
    endpoint: [
      type: :string,
      required: true
    ],
    method: [
      type: {:in, [:get, :post]},
      default: :post
    ],
    headers: [
      type: {:map, :string, {:or, [nil, :boolean, :integer, :float, :string]}},
      default: %{}
    ],
    version: [
      type: :string,
      required: true
    ],
    action: [
      type: :string,
      required: true
    ],
    params: [
      type: {:or, [{:map, :any, :any}, nil]},
      default: nil
    ]
  ]

  @enforce_keys [
    :config,
    :endpoint,
    :method,
    :headers,
    :version,
    :action,
    :params
  ]

  defstruct @enforce_keys

  @type endpoint :: String.t()
  @type method :: :get | :post
  @type headers :: %{
          optional(name :: String.t()) => value :: nil | boolean() | number() | String.t()
        }

  @type version :: String.t()
  @type action :: String.t()
  @type params ::
          %{
            optional(name :: String.t()) => value :: nil | boolean() | number() | String.t()
          }
          | nil

  @type spec_opt ::
          {:endpoint, endpoint()}
          | {:method, method()}
          | {:headers, headers()}
          | {:version, version()}
          | {:action, action()}
          | {:params, params()}
  @type spec_opts :: [spec_opt()]

  @type t :: %__MODULE__{
          config: Config.t(),
          endpoint: endpoint(),
          method: method(),
          headers: headers(),
          version: version(),
          action: action(),
          params: params()
        }

  @spec new!(Config.t(), spec_opts()) :: t()
  def new!(%Config{} = config, spec_opts) do
    spec_opts
    |> NimbleOptions.validate!(@spec_opts_schema)
    |> then(&struct(__MODULE__, &1))
    |> put_config(config)
  end

  defp put_config(struct, config), do: Map.put(struct, :config, config)
end

defimpl AliyunOpenAPI.HTTP.Request.Transform,
  for: AliyunOpenAPI.Specs.RPC do
  import AliyunOpenAPI.Utils, only: [parse_base_url: 1]
  alias AliyunOpenAPI.EasyTime
  alias AliyunOpenAPI.Specs.RPC
  alias AliyunOpenAPI.HTTP.Request
  alias AliyunOpenAPI.Sign.ACS3

  def to_request!(%RPC{method: :get} = rpc) do
    now = EasyTime.utc_now(:second)

    %{
      config: config,
      endpoint: endpoint,
      method: method,
      version: version,
      action: action,
      headers: headers,
      params: params
    } = rpc

    %{scheme: scheme, host: host, port: port} = parse_base_url(endpoint)

    Request.new!(%{
      scheme: scheme,
      host: host,
      port: port,
      method: method,
      path: "/",
      query: params,
      headers: headers
    })
    |> Request.put_header("x-acs-version", version)
    |> Request.put_header("x-acs-action", action)
    |> ACS3.sign(at: now, config: config)
  end

  def to_request!(%RPC{method: :post} = rpc) do
    now = EasyTime.utc_now(:second)

    %{
      config: config,
      endpoint: endpoint,
      method: method,
      version: version,
      action: action,
      headers: headers,
      params: params
    } = rpc

    %{scheme: scheme, host: host, port: port} = parse_base_url(endpoint)

    Request.new!(%{
      scheme: scheme,
      host: host,
      port: port,
      method: method,
      path: "/",
      headers: headers
    })
    |> Request.put_header("x-acs-version", version)
    |> Request.put_header("x-acs-action", action)
    |> put_post_params(params)
    |> ACS3.sign(at: now, config: config)
  end

  defp put_post_params(%{method: :post} = request, params) do
    request
    |> Request.put_header("content-type", "application/x-www-form-urlencoded")
    |> Request.put_body(URI.encode_query(params, :www_form))
  end
end
