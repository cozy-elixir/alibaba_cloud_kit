defmodule AlibabaCloudKit.Signature.OSS4 do
  @moduledoc """
  An implementation for OSS V4 signature.

  This type of signature is used by:

    * Object Storage Service (OSS)

  Read more at:

    * [Object Storage Service > Developer Reference > Use the RESTful API to initiate requests](https://www.alibabacloud.com/help/en/oss/developer-reference/use-the-restful-api-to-initiate-requests/)
    * [对象存储 > 开发参考 > 开发指南 > 使用 REST API 发起请求](https://help.aliyun.com/zh/oss/developer-reference/use-the-restful-api-to-initiate-requests/)

  """

  import AlibabaCloudKit.Utils,
    only: [
      utc_now: 1,
      to_rfc1123: 1,
      to_basic_iso8601: 1,
      encode_json!: 1,
      encode_rfc3986: 1,
      md5: 1,
      sha256: 1,
      hmac_sha256: 2,
      base16: 1,
      base64: 1
    ]

  alias HTTPSpec.Request
  alias AlibabaCloudKit.OSS.Object.PostPolicy

  @type access_key_id :: String.t()
  @type access_key_secret :: String.t()
  @type region :: String.t()
  @type bucket :: String.t() | nil
  @type sign_type :: :header | :query
  @type at :: DateTime.t() | nil

  @type sign_opt ::
          {:access_key_id, access_key_id()}
          | {:access_key_secret, access_key_secret()}
          | {:region, region()}
          | {:bucket, bucket()}
          | {:sign_type, sign_type()}
          | {:at, at()}
  @type sign_opts :: [sign_opt()]

  @sign_opts_definition NimbleOptions.new!(
                          access_key_id: [
                            type: :string,
                            required: true
                          ],
                          access_key_secret: [
                            type: :string,
                            required: true
                          ],
                          region: [
                            type: :string,
                            required: true
                          ],
                          bucket: [
                            type: {:or, [:string, nil]},
                            default: nil
                          ],
                          sign_type: [
                            type: {:in, [:header, :query]},
                            default: :header
                          ],
                          at: [
                            type: {:or, [{:struct, DateTime}, nil]},
                            default: nil
                          ]
                        )

  @signature_version "OSS4-HMAC-SHA256"
  @access_key_version "aliyun_v4"
  @request_version "aliyun_v4_request"
  @service_name "oss"

  @doc """
  Signs a request.

  ## The location to put signature

  The location to put signature is controlled by the `:sign_type` option:

    * `:header` (default) - add signature to the headers of a request.
    * `:query` - add signature to the query of a request.

  ### Automatically added request headers when using `:header` sign type

  Following headers will be added to the request automatically:

    * `host`
    * `date`
    * `content-md5` (overridable)
    * `content-type` (overridable)
    * `x-oss-date`
    * `x-oss-content-sha256`
    * `authorization`

  ### Automatically added request queries when using `:query` sign type

  Following queries will be added to the request automatically:

    * `x-oss-signature-version`
    * `x-oss-signature`
    * `x-oss-credential`
    * `x-oss-date`
    * `x-oss-expires` (overridable)
    * `x-oss-additional-headers`

  ## Required headers

  All necessary headers of requests will be generated automatically. You don't
  have to specifically set them, unless you want to customize it.

  ## Examples

  ### Build and sign a request for `ListBucktets` operation

      request = HTTPSpec.Request.new!(
        method: :get,
        scheme: :https,
        host: "oss-us-west-1.aliyuncs.com",
        port: 443,
        path: "/"
      )

      opts = [
        access_key_id: "...",
        access_key_secret: "...",
        region: "oss-us-west-1",
        sign_type: :header
      ]

      AlibabaCloudKit.Signature.OSS4.sign!(request, opts)

  ### Build a pre-signed url for `GetObject` operation

      request = HTTPSpec.Request.new!(
        method: :get,
        scheme: :https,
        host: "example-bucket.oss-us-west-1.aliyuncs.com",
        port: 443,
        path: "/example-object",
        query: "x-oss-expires=900"
      )

      opts = [
        access_key_id: "...",
        access_key_secret: "...",
        region: "oss-us-west-1",
        bucket: "example-bucket",
        sign_type: :query
      ]

      request
      |> AlibabaCloudKit.Signature.OSS4.sign!(opts)
      |> HTTPSpec.Request.build_url()

  """
  @spec sign!(Request.t(), sign_opts()) :: Request.t()
  def sign!(%Request{} = request, opts) do
    %{
      access_key_id: access_key_id,
      access_key_secret: access_key_secret,
      region: region,
      bucket: bucket,
      sign_type: sign_type,
      at: at
    } =
      opts
      |> NimbleOptions.validate!(@sign_opts_definition)
      |> Map.new()

    at = at || utc_now(:second)
    datetime_in_rfc1123 = to_rfc1123(at)
    datetime_in_iso8601 = to_basic_iso8601(at)
    date_in_iso8601 = DateTime.to_date(at) |> to_basic_iso8601()

    ctx = %{
      access_key_id: access_key_id,
      access_key_secret: access_key_secret,
      region: sanitize_region(region),
      bucket: bucket,
      sign_type: sign_type,
      datetime: datetime_in_iso8601,
      date: date_in_iso8601
    }

    request
    |> Request.put_header("host", request.host)
    |> Request.put_header("date", datetime_in_rfc1123)
    |> put_signature(ctx)
  end

  @doc false
  def sign(%PostPolicy{} = post_policy, %{
        access_key_id: access_key_id,
        access_key_secret: access_key_secret,
        region: region,
        bucket: bucket,
        at: at
      }) do
    at = at || utc_now(:second)
    datetime_in_iso8601 = to_basic_iso8601(at)
    date_in_iso8601 = DateTime.to_date(at) |> to_basic_iso8601()

    ctx = %{
      access_key_id: access_key_id,
      access_key_secret: access_key_secret,
      region: sanitize_region(region),
      bucket: bucket,
      datetime: datetime_in_iso8601,
      date: date_in_iso8601
    }

    %{
      post_policy: build_string_to_sign(post_policy, ctx),
      signature: build_signature(post_policy, ctx)
    }
  end

  @doc false
  def prepare_sign_info_for_post_policy(%{
        access_key_id: access_key_id,
        access_key_secret: access_key_secret,
        region: region,
        bucket: bucket,
        at: at
      }) do
    at = at || utc_now(:second)
    datetime_in_iso8601 = to_basic_iso8601(at)
    date_in_iso8601 = DateTime.to_date(at) |> to_basic_iso8601()

    ctx = %{
      access_key_id: access_key_id,
      access_key_secret: access_key_secret,
      region: sanitize_region(region),
      bucket: bucket,
      datetime: datetime_in_iso8601,
      date: date_in_iso8601
    }

    %{
      signature_version: @signature_version,
      credential: build_credential(ctx),
      datetime: datetime_in_iso8601,
      at: at
    }
  end

  defp sanitize_region(region) do
    String.trim_leading(region, "oss-")
  end

  defp put_signature(request, %{sign_type: :header} = ctx) do
    %{datetime: datetime} = ctx

    request
    |> Request.put_new_lazy_header("content-md5", &build_content_md5(&1))
    |> Request.put_new_lazy_header("content-type", &detect_content_type(&1))
    |> Request.put_header("x-oss-date", datetime)
    |> Request.put_header("x-oss-content-sha256", build_hashed_payload(request))
    |> Request.put_new_lazy_header("authorization", fn request ->
      additional_headers = build_additional_headers(request)

      content =
        [
          "Credential=#{build_credential(ctx)}",
          if(additional_headers != [], do: "AdditionalHeaders=#{additional_headers}", else: nil),
          "Signature=#{build_signature(request, ctx)}"
        ]
        |> Enum.reject(&(&1 == nil))
        |> Enum.join(",")

      "#{@signature_version} #{content}"
    end)
  end

  defp put_signature(request, %{sign_type: :query} = ctx) do
    %{datetime: datetime} = ctx

    query_params =
      Request.Query.decode(request.query)
      |> Request.Query.put("x-oss-signature-version", @signature_version)
      |> Request.Query.put("x-oss-credential", build_credential(ctx))
      |> Request.Query.put("x-oss-date", datetime)
      |> Request.Query.put_new_lazy("x-oss-expires", fn -> 3600 end)
      |> Request.Query.put_new_lazy("x-oss-additional-headers", fn ->
        build_additional_headers(request)
      end)

    request = Request.put_query(request, Request.Query.encode(query_params))

    query =
      query_params
      |> Request.Query.put_new_lazy("x-oss-signature", fn -> build_signature(request, ctx) end)
      |> Request.Query.encode()

    Request.put_query(request, query)
  end

  defp build_content_md5(request) do
    (request.body || "")
    |> md5()
    |> base64()
  end

  defp detect_content_type(request) do
    case Path.extname(request.path) do
      "." <> name -> MIME.type(name)
      _ -> "application/octet-stream"
    end
  end

  defp build_credential(ctx) do
    %{
      access_key_id: access_key_id,
      date: date,
      region: region
    } = ctx

    Enum.join([access_key_id, date, region, @service_name, @request_version], "/")
  end

  defp build_signature(request_or_post_policy, ctx) do
    %{
      access_key_secret: access_key_secret,
      date: date,
      region: region
    } = ctx

    "#{@access_key_version}#{access_key_secret}"
    |> hmac_sha256(date)
    |> hmac_sha256(region)
    |> hmac_sha256(@service_name)
    |> hmac_sha256(@request_version)
    |> hmac_sha256(build_string_to_sign(request_or_post_policy, ctx))
    |> base16()
  end

  defp build_string_to_sign(%Request{} = request, ctx) do
    %{date: date, region: region, datetime: datetime} = ctx

    scope = Enum.join([date, region, @service_name, @request_version], "/")
    canonical_request = build_canonical_request(request, ctx)

    [
      @signature_version,
      datetime,
      scope,
      canonical_request |> sha256() |> base16()
    ]
    |> Enum.join("\n")
  end

  defp build_string_to_sign(%PostPolicy{} = post_policy, _ctx) do
    post_policy
    |> Map.from_struct()
    |> encode_json!()
    |> base64()
  end

  defp build_canonical_request(request, ctx) do
    [
      build_method(request),
      build_canonical_path(request, ctx),
      build_canonical_querystring(request),
      build_canonical_headers(request),
      build_additional_headers(request),
      build_hashed_payload(request)
    ]
    |> Enum.join("\n")
  end

  defp build_method(request) do
    Request.build_method(request)
  end

  defp build_canonical_path(request, ctx) do
    bucket = ctx.bucket
    path = request.path

    if(bucket,
      do: "/#{bucket}#{URI.decode(path)}",
      else: URI.decode(path)
    )
    |> String.split("/")
    |> Enum.map_join("/", &encode_rfc3986/1)
  end

  defp build_canonical_querystring(request) do
    request.query
    |> Request.Query.decode()
    |> Map.fetch!(:internal)
    |> Enum.sort()
    |> Enum.map_join("&", fn
      {k, nil} -> encode_rfc3986(k)
      {k, ""} -> encode_rfc3986(k)
      {k, v} -> encode_rfc3986(k) <> "=" <> encode_rfc3986(v)
    end)
  end

  defp build_canonical_headers(request) do
    request.headers
    |> Enum.reject(&ignored_header?/1)
    |> sort_headers()
    |> Enum.map_join("", fn {k, v} -> "#{k}:#{v}\n" end)
  end

  defp build_additional_headers(request) do
    request.headers
    |> Enum.reject(fn kv -> ignored_header?(kv) || canoncial_header?(kv) end)
    |> sort_headers()
    |> Enum.map_join(";", fn {k, _v} -> k end)
  end

  defp build_hashed_payload(_request) do
    "UNSIGNED-PAYLOAD"
  end

  defp sort_headers(headers) do
    Enum.sort_by(headers, &elem(&1, 0), :asc)
  end

  defp ignored_header?({k, _v}) do
    k in ["date"]
  end

  defp canoncial_header?({k, _v}) do
    k in ["content-type", "content-md5"] ||
      String.starts_with?(k, "x-oss-")
  end
end
