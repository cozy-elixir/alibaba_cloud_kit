defmodule AliyunOpenAPI.Specs.OSS do
  @moduledoc """
  Describes an OSS style API.

  Read more at:

    * [Object Storage Service > Developer Reference > Use the RESTful API to initiate requests](https://www.alibabacloud.com/help/en/oss/developer-reference/use-the-restful-api-to-initiate-requests/)
    * [Object Storage Service > Developer Reference > Use the RESTful API to initiate requests (zh-Hans)](https://help.aliyun.com/zh/oss/developer-reference/use-the-restful-api-to-initiate-requests/)

  ## About `spec_opts`

  `spec_opts` is a plain map for describing a RESTful API request.

  ### Adding signature

  This implementation has built-in V4 signature support, and it's controlled
  by the `:sign_type` option:

    * `:header` - add signature to the headers of request.
    * `:url` - add signature to the url of request.

  > V1 signature is not supported.

  ### Required headers

  All necessary headers of requests will be generated automatically. You don't
  have to specifically set them, unless you want to customize it.

  ## Examples

  ### Send a request for `ListBucktets` operation

      alias AliyunOpenAPI.Config
      alias AliyunOpenAPI.Specs.OSS
      alias AliyunOpenAPI.HTTP.Request
      alias AliyunOpenAPI.HTTP.Client

      config =
        Config.new!(
          access_key_id: "...",
          access_key_secret: "..."
        )

      OSS.new!(config,
        sign_type: :header,
        region: "oss-us-west-1",
        endpoint: "https://oss-us-west-1.aliyuncs.com/",
        method: :get,
        path: "/"
      )
      |> Request.from_spec!()
      |> Client.request()

  ### Create a pre-signed url for `GetObject` operation

      alias AliyunOpenAPI.Config
      alias AliyunOpenAPI.Specs.OSS
      alias AliyunOpenAPI.HTTP.Request

      config =
        Config.new!(
          access_key_id: "...",
          access_key_secret: "..."
        )

      OSS.new!(config,
        sign_type: :url,
        region: "oss-us-west-1",
        bucket: "example-bucket",
        endpoint: "https://example-bucket.oss-us-west-1.aliyuncs.com/",
        method: :get,
        path: "/example-object",
        headers: %{
          "x-oss-expires" => 900
        }
      )
      |> Request.from_spec!()
      |> Request.url()

  """

  alias AliyunOpenAPI.Config

  @spec_opts_schema [
    region: [
      type: :string,
      required: true
    ],
    bucket: [
      type: {:or, [:string, nil]},
      default: nil
    ],
    sign_type: [
      type: {:in, [:header, :url]},
      default: :header
    ],
    endpoint: [
      type: :string,
      required: true
    ],
    method: [
      type: {:in, [:head, :get, :post, :put, :patch, :delete]},
      required: true
    ],
    path: [
      type: :string,
      default: "/"
    ],
    query: [
      type: {:map, :string, {:or, [nil, :boolean, :integer, :float, :string]}},
      default: %{}
    ],
    headers: [
      type: {:map, :string, {:or, [nil, :boolean, :integer, :float, :string]}},
      default: %{}
    ],
    body: [
      type: :any,
      default: nil
    ]
  ]

  @enforce_keys [
    :config,
    :region,
    :bucket,
    :sign_type,
    :endpoint,
    :method,
    :path,
    :query,
    :headers,
    :body
  ]

  defstruct @enforce_keys

  @type region :: String.t()
  @type bucket :: String.t() | nil
  @type sign_type :: :header | :url

  @typedoc """
  The base url that the request is sent to.

  Following formats are supported:

    * region URL, such as `https://oss-us-west-1.aliyuncs.com`.
    * virtual-hosted style URL, such as `https://example-bucket.oss-us-west-1.aliyuncs.com`.
    * custom domain name, such as `https://www.example.com`.
    * ...

  """
  @type endpoint :: String.t()

  @type method :: String.t()
  @type path :: String.t()
  @type query :: %{
          optional(name :: String.t()) => value :: nil | boolean() | number() | String.t()
        }
  @type headers :: %{
          optional(name :: String.t()) => value :: nil | boolean() | number() | String.t()
        }
  @type body :: iodata() | nil

  @type spec_opt ::
          {:region, region()}
          | {:bucket, bucket()}
          | {:sign_type, sign_type()}
          | {:endpoint, endpoint()}
          | {:method, method()}
          | {:path, path()}
          | {:query, query()}
          | {:headers, headers()}
          | {:body, body()}
  @type spec_opts :: [spec_opt()]

  @type t :: %__MODULE__{
          config: Config.t(),
          region: region(),
          bucket: bucket(),
          sign_type: sign_type(),
          endpoint: endpoint(),
          method: method(),
          path: path(),
          query: query(),
          headers: headers(),
          body: body()
        }

  @spec new!(Config.t(), spec_opts()) :: t()
  def new!(%Config{} = config, spec_opts) when is_list(spec_opts) do
    spec_opts
    |> NimbleOptions.validate!(@spec_opts_schema)
    |> then(&struct(__MODULE__, &1))
    |> put_config(config)
    |> normalize_path!()
  end

  defp put_config(struct, config), do: Map.put(struct, :config, config)

  defp normalize_path!(struct) do
    Map.update!(struct, :path, &Path.join("/", &1))
  end
end

defimpl AliyunOpenAPI.HTTP.Request.Transform,
  for: AliyunOpenAPI.Specs.OSS do
  import AliyunOpenAPI.Utils, only: [parse_base_url: 1]
  alias AliyunOpenAPI.EasyTime
  alias AliyunOpenAPI.Specs.OSS
  alias AliyunOpenAPI.HTTP.Request
  alias AliyunOpenAPI.Sign.OSS4

  def to_request!(%OSS{} = oss) do
    now = EasyTime.utc_now(:second)

    %{
      config: config,
      region: region,
      bucket: bucket,
      sign_type: type,
      endpoint: endpoint,
      method: method,
      path: path,
      query: query,
      headers: headers,
      body: body
    } = oss

    %{scheme: scheme, host: host, port: port} = parse_base_url(endpoint)

    Request.new!(%{
      scheme: scheme,
      host: host,
      port: port,
      method: method,
      path: path,
      query: query,
      headers: headers,
      body: body
    })
    |> Request.put_header("host", host)
    |> Request.put_new_header("date", fn _request -> EasyTime.to_rfc1123(now) end)
    |> OSS4.sign(at: now, type: type, config: config, region: region, bucket: bucket)
  end
end
