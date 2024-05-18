defmodule CozyAliyunOpenAPI.Specs.OSS do
  @moduledoc """
  Describes an OSS style API.

  Read more at:

    * [Object Storage Service > Developer Reference > Use the RESTful API to initiate requests](https://www.alibabacloud.com/help/en/oss/developer-reference/use-the-restful-api-to-initiate-requests/)
    * [Object Storage Service > Developer Reference > Use the RESTful API to initiate requests (zh-Hans)](https://help.aliyun.com/zh/oss/developer-reference/use-the-restful-api-to-initiate-requests/)

  ## About `spec_config`

  `spec_config` is a plain map for describing a RESTful API request.

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

      alias CozyAliyunOpenAPI.Config
      alias CozyAliyunOpenAPI.Specs.OSS
      alias CozyAliyunOpenAPI.HTTPRequest
      alias CozyAliyunOpenAPI.HTTPClient

      config =
        Config.new!(%{
          access_key_id: "...",
          access_key_secret: "..."
        })

      OSS.new!(config, %{
        sign_type: :header,
        region: "oss-us-west-1",
        method: :get,
        endpoint: "https://oss-us-west-1.aliyuncs.com/",
        path: "/"
      })
      |> HTTPRequest.from_spec!()
      |> HTTPClient.request()

  ### Create a pre-signed url for `GetObject` operation

      alias CozyAliyunOpenAPI.Config
      alias CozyAliyunOpenAPI.Specs.OSS
      alias CozyAliyunOpenAPI.HTTPRequest

      config =
        Config.new!(%{
          access_key_id: "...",
          access_key_secret: "..."
        })

      OSS.new!(config, %{
        sign_type: :url,
        region: "oss-us-west-1",
        bucket: "example-bucket",
        method: :get,
        endpoint: "https://example-bucket.oss-us-west-1.aliyuncs.com/",
        path: "/example-object",
        headers: %{
          "x-oss-expires" => 900
        }
      })
      |> HTTPRequest.from_spec!()
      |> HTTPRequest.url()

  """

  alias CozyAliyunOpenAPI.Config

  @spec_config_schema [
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
    method: [
      type: {:in, [:head, :get, :post, :put, :patch, :delete]},
      required: true
    ],
    endpoint: [
      type: :string,
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
    :method,
    :endpoint,
    :path,
    :query,
    :headers,
    :body
  ]

  defstruct @enforce_keys

  @type region() :: String.t()
  @type bucket() :: String.t() | nil
  @type sign_type() :: :header | :url
  @type method() :: String.t()

  @typedoc """
  The base url that the request is sent to.

  Following formats are supported:

    * region URL, such as `https://oss-us-west-1.aliyuncs.com`.
    * virtual-hosted style URL, such as `https://example-bucket.oss-us-west-1.aliyuncs.com`.
    * custom domain name, such as `https://www.example.com`.
    * ...

  """
  @type endpoint() :: String.t()
  @type path() :: String.t()
  @type query() :: %{
          optional(name :: String.t()) => value :: nil | boolean() | number() | String.t()
        }
  @type headers() :: %{
          optional(name :: String.t()) => value :: nil | boolean() | number() | String.t()
        }
  @type body() :: iodata() | nil

  @type spec_config() :: %{
          region: region(),
          bucket: bucket(),
          sign_type: sign_type(),
          method: method(),
          endpoint: endpoint(),
          path: path(),
          query: query(),
          headers: headers(),
          body: body()
        }

  @type t :: %__MODULE__{
          config: Config.t(),
          region: region(),
          bucket: bucket(),
          sign_type: sign_type(),
          method: method(),
          endpoint: endpoint(),
          path: path(),
          query: query(),
          headers: headers(),
          body: body()
        }

  @spec new!(Config.t(), spec_config()) :: t()
  def new!(%Config{} = config, spec_config) when is_map(spec_config) do
    spec_config =
      spec_config
      |> Map.to_list()
      |> NimbleOptions.validate!(@spec_config_schema)

    struct(__MODULE__, spec_config)
    |> put_config(config)
    |> normalize_path!()
    |> normalize_headers!()
  end

  defp put_config(struct, config), do: Map.put(struct, :config, config)

  defp normalize_path!(struct) do
    Map.update!(struct, :path, &Path.join("/", &1))
  end

  defp normalize_headers!(struct) do
    Map.update!(
      struct,
      :headers,
      &Enum.into(&1, %{}, fn {k, v} ->
        {
          k |> Kernel.to_string() |> String.trim() |> String.downcase(),
          v |> Kernel.to_string() |> String.trim()
        }
      end)
    )
  end
end

alias CozyAliyunOpenAPI.Specs.OSS
alias CozyAliyunOpenAPI.HTTPRequest
alias CozyAliyunOpenAPI.EasyTime

defimpl HTTPRequest.Transform, for: OSS do
  import CozyAliyunOpenAPI.Specs.Utils,
    only: [
      parse_base_url: 1,
      md5: 1,
      sha256: 1,
      hmac_sha256: 2,
      base16: 1,
      base64: 1,
      encode_rfc3986: 1
    ]

  def to_request!(%OSS{} = oss) do
    utc_datetime = EasyTime.utc_now(:second)
    utc_date = EasyTime.utc_today()

    utc_datetime_in_iso8601 = EasyTime.to_basic_iso8601(utc_datetime)
    utc_datetime_in_rfc1123 = EasyTime.to_rfc1123(utc_datetime)
    utc_date_in_iso8601 = EasyTime.to_basic_iso8601(utc_date)

    %{
      config: config,
      region: region,
      bucket: bucket,
      sign_type: sign_type,
      method: method,
      endpoint: endpoint,
      path: path,
      query: query,
      headers: headers,
      body: body
    } = oss

    %{scheme: scheme, host: host, port: port} = parse_base_url(endpoint)

    request =
      HTTPRequest.new!(%{
        scheme: scheme,
        host: host,
        port: port,
        method: method,
        path: path,
        query: query,
        headers: headers,
        body: body
      })
      |> HTTPRequest.put_header("host", host)
      |> HTTPRequest.put_header_lazy("date", fn -> utc_datetime_in_rfc1123 end)

    sign_args = %{
      sign_type: sign_type,
      signature_version: "OSS4-HMAC-SHA256",
      access_key_version: "aliyun_v4",
      request_version: "aliyun_v4_request",
      service: "oss",
      datetime: utc_datetime_in_iso8601,
      date: utc_date_in_iso8601,
      config: config,
      region: String.trim_leading(region, "oss-"),
      bucket: bucket
    }

    put_sign({request, sign_args})
  end

  defp put_sign({request, %{sign_type: :header} = sign_args}) do
    %{
      signature_version: signature_version,
      datetime: datetime
    } = sign_args

    request =
      request
      |> HTTPRequest.put_header_lazy("content-md5", &build_content_md5(&1))
      |> HTTPRequest.put_header_lazy("content-type", &detect_content_type(&1))
      # x-oss-date is required, even if the documentation doesn't mention it ;)
      |> HTTPRequest.put_header("x-oss-date", datetime)
      |> HTTPRequest.put_header("x-oss-content-sha256", "UNSIGNED-PAYLOAD")

    # Set and use additional_headers after request is updated.
    sign_args = Map.put(sign_args, :additional_headers, extract_additional_headers(request))
    %{additional_headers: additional_headers} = sign_args

    content =
      [
        "Credential=#{build_credential({request, sign_args})}",
        if(additional_headers != [], do: "AdditionalHeaders=#{additional_headers}", else: nil),
        "Signature=#{sign({request, sign_args})}"
      ]
      |> Enum.reject(&(&1 == nil))
      |> Enum.join(", ")

    authorization = "#{signature_version} #{content}"

    request
    |> HTTPRequest.put_header("authorization", authorization)
  end

  defp put_sign({request, %{sign_type: :url} = sign_args}) do
    %{
      signature_version: signature_version,
      datetime: datetime
    } = sign_args

    request =
      request
      |> HTTPRequest.put_query("x-oss-signature-version", signature_version)
      |> HTTPRequest.put_query("x-oss-credential", build_credential({request, sign_args}))
      |> HTTPRequest.put_query("x-oss-date", datetime)
      |> HTTPRequest.put_query_lazy("x-oss-expires", fn -> 3600 end)

    # Set and use additional_headers after request is updated.
    sign_args = Map.put(sign_args, :additional_headers, extract_additional_headers(request))
    %{additional_headers: additional_headers} = sign_args

    request =
      HTTPRequest.put_query(request, "x-oss-additional-headers", additional_headers)

    request
    |> HTTPRequest.put_query("x-oss-signature", sign({request, sign_args}))
  end

  defp build_content_md5(request) do
    %{body: body} = request

    (body || "")
    |> md5()
    |> base64()
  end

  defp detect_content_type(request) do
    case Path.extname(request.path) do
      "." <> name -> MIME.type(name)
      _ -> "application/octet-stream"
    end
  end

  defp extract_additional_headers(request) do
    request.headers
    |> Enum.reject(fn kv -> is_ignored_header?(kv) || is_canoncial_header?(kv) end)
    |> sort_headers()
    |> Enum.map_join(";", fn {k, _v} -> k end)
  end

  defp build_credential({_request, sign_args}) do
    %{
      config: %{access_key_id: access_key_id},
      request_version: request_version,
      service: service,
      region: region,
      date: date
    } = sign_args

    Enum.join([access_key_id, date, region, service, request_version], "/")
  end

  defp sign({request, sign_args}) do
    %{
      config: %{access_key_secret: access_key_secret},
      access_key_version: access_key_version,
      request_version: request_version,
      service: service,
      region: region,
      date: date
    } = sign_args

    "#{access_key_version}#{access_key_secret}"
    |> hmac_sha256(date)
    |> hmac_sha256(region)
    |> hmac_sha256(service)
    |> hmac_sha256(request_version)
    |> hmac_sha256(build_string_to_sign({request, sign_args}))
    |> base16()
  end

  defp build_string_to_sign({request, sign_args}) do
    %{
      request_version: request_version,
      service: service,
      region: region,
      datetime: datetime,
      date: date
    } = sign_args

    scope = Enum.join([date, region, service, request_version], "/")
    canonical_request = build_canonical_request({request, sign_args})

    [
      "OSS4-HMAC-SHA256",
      datetime,
      scope,
      canonical_request |> sha256() |> base16()
    ]
    |> Enum.join("\n")
  end

  defp build_canonical_request({request, sign_args}) do
    [
      build_method({request, sign_args}),
      build_canonical_path({request, sign_args}),
      build_canonical_querystring({request, sign_args}),
      build_canonical_headers({request, sign_args}),
      build_additional_headers({request, sign_args}),
      build_hashed_payload({request, sign_args})
    ]
    |> Enum.join("\n")
  end

  defp build_method({request, _sign_args}) do
    request.method
    |> Atom.to_string()
    |> String.upcase()
  end

  defp build_canonical_path({request, sign_args}) do
    %{bucket: bucket} = sign_args
    path = request.path

    if(bucket,
      do: "/#{bucket}#{path}",
      else: path
    )
    |> URI.encode()
  end

  defp build_canonical_querystring({request, _sign_args}) do
    request.query
    |> Enum.sort()
    |> Enum.map_join("&", fn
      {k, nil} -> encode_rfc3986(k)
      {k, ""} -> encode_rfc3986(k)
      {k, v} -> encode_rfc3986(k) <> "=" <> encode_rfc3986(v)
    end)
  end

  defp build_canonical_headers({request, _sign_args}) do
    request.headers
    |> Enum.reject(&is_ignored_header?/1)
    |> sort_headers()
    |> Enum.map_join("", fn {k, v} -> "#{k}:#{v}\n" end)
  end

  defp build_additional_headers({_request, sign_args}) do
    sign_args.additional_headers
  end

  defp build_hashed_payload({_request, _sign_args}) do
    "UNSIGNED-PAYLOAD"
  end

  defp sort_headers(headers) do
    Enum.sort_by(headers, &elem(&1, 0), :asc)
  end

  defp is_ignored_header?({k, _v}) do
    k in ["date"]
  end

  defp is_canoncial_header?({k, _v}) do
    k in ["content-type", "content-md5"] ||
      String.starts_with?(k, "x-oss-")
  end
end
