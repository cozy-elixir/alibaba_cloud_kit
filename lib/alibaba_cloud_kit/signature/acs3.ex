defmodule AlibabaCloudKit.Signature.ACS3 do
  @moduledoc """
  An implementation for ACS V3 signature.

  This type of signature is used by most of RPC style APIs:

    * Elastic Compute Service (ECS)
    * Content Delivery Network (CDN)
    * ApsaraDB RDS
    * ...

  Read more at:

    * [Alibaba Cloud SDK > Product Overview > Request syntax and signature method V3](https://www.alibabacloud.com/help/en/sdk/product-overview/v3-request-structure-and-signature)
    * [阿里云 SDK > 产品概述 > 请求结构和签名机制 > V3 版本请求体 & 签名机制](https://help.aliyun.com/zh/sdk/product-overview/request-structure-and-signature)

  """

  import AlibabaCloudKit.Utils,
    only: [
      utc_now: 1,
      to_extended_iso8601: 1,
      random_string: 0,
      sha256: 1,
      hmac_sha256: 2,
      base16: 1
    ]

  alias HTTPSpec.Request

  @type access_key_id :: String.t()
  @type access_key_secret :: String.t()
  @type at :: DateTime.t() | nil

  @type sign_opt ::
          {:access_key_id, access_key_id()}
          | {:access_key_secret, access_key_secret()}
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
                          at: [
                            type: {:or, [{:struct, DateTime}, nil]},
                            default: nil
                          ]
                        )

  @signature_version "ACS3-HMAC-SHA256"

  @doc """
  Signs a request.

  ## Automatically added request headers

  Following headers will be added to the request automatically:

    * `host`
    * `x-acs-date`
    * `x-acs-content-sha256`
    * `x-acs-signature-nonce`
    * `authorization`

  ## Examples

  ### Build and sign a GET request

      request = HTTPSpec.Request.new!(
        method: :get,
        scheme: :https,
        host: "ecs-us-west-1.aliyuncs.com",
        port: 443,
        path: "/",
        query: URI.encode_query(%{"RegionId" => "us-west-1"}, :rfc3986),
        headers: [
          {"x-acs-version", "2014-05-26"},
          {"x-acs-action", "DescribeInstanceStatus"}
        ]
      )

      opts = [
        access_key_id: "...",
        access_key_secret: "..."
      ]

      AlibabaCloudKit.Signature.ACS3.sign!(request, opts)

  ### Build and sign a POST request

      request = HTTPSpec.Request.new!(
        method: :post,
        scheme: :https,
        host: "ecs-us-west-1.aliyuncs.com",
        port: 443,
        path: "/",
        headers: [
          {"content-type", "application/x-www-form-urlencoded"},
          {"x-acs-version", "2014-05-26"},
          {"x-acs-action", "DescribeInstanceStatus"}
        ],
        body: URI.encode_query(%{"RegionId" => "us-west-1"}, :www_form)
      )

      opts = [
        access_key_id: "...",
        access_key_secret: "..."
      ]

      AlibabaCloudKit.Signature.ACS3.sign!(request, opts)

  """
  def sign!(%Request{} = request, opts) do
    %{
      access_key_id: access_key_id,
      access_key_secret: access_key_secret,
      at: at
    } =
      opts
      |> NimbleOptions.validate!(@sign_opts_definition)
      |> Map.new()

    at = at || utc_now(:second)
    datetime = to_extended_iso8601(at)

    ctx = %{
      access_key_id: access_key_id,
      access_key_secret: access_key_secret
    }

    request
    |> Request.put_header("host", request.host)
    |> Request.put_header("x-acs-date", datetime)
    |> Request.put_header("x-acs-content-sha256", build_hashed_payload(request))
    |> Request.put_new_lazy_header("x-acs-signature-nonce", fn -> random_string() end)
    |> Request.put_new_lazy_header("authorization", fn request ->
      build_authorization(request, ctx)
    end)
  end

  defp build_authorization(request, ctx) do
    credential = ctx.access_key_id
    signed_headers = build_signed_headers(request)
    signature = build_signature(request, ctx.access_key_secret)

    content =
      [
        "Credential=#{credential}",
        "SignedHeaders=#{signed_headers}",
        "Signature=#{signature}"
      ]
      |> Enum.join(",")

    "#{@signature_version} #{content}"
  end

  defp build_signature(request, secret) do
    secret
    |> hmac_sha256(build_string_to_sign(request))
    |> base16()
  end

  defp build_string_to_sign(request) do
    [
      @signature_version,
      build_canonical_request(request) |> sha256() |> base16()
    ]
    |> Enum.join("\n")
  end

  defp build_canonical_request(request) do
    [
      build_method(request),
      build_canonical_path(request),
      build_canonical_querystring(request),
      build_canonical_headers(request),
      build_signed_headers(request),
      build_hashed_payload(request)
    ]
    |> Enum.join("\n")
  end

  defp build_method(request) do
    Request.build_method(request)
  end

  defp build_canonical_path(request) do
    request.path
    |> URI.encode()
  end

  defp build_canonical_querystring(request) do
    request.query
    |> Request.Query.decode()
    |> Map.fetch!(:internal)
    |> Enum.sort()
    |> URI.encode_query(:rfc3986)
  end

  defp build_canonical_headers(request) do
    request.headers
    |> Enum.reject(&ignored_header?/1)
    |> sort_headers()
    |> Enum.map_join("", fn {k, v} -> "#{k}:#{v}\n" end)
  end

  defp build_signed_headers(request) do
    request.headers
    |> Enum.reject(&ignored_header?/1)
    |> sort_headers()
    |> Enum.map_join(";", fn {k, _v} -> k end)
  end

  defp build_hashed_payload(request) do
    (request.body || "")
    |> sha256()
    |> base16()
  end

  defp sort_headers(headers) do
    Enum.sort_by(headers, &elem(&1, 0), :asc)
  end

  defp ignored_header?({k, _v}) do
    k in ["date"]
  end
end
