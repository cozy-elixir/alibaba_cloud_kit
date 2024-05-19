defmodule CozyAliyunOpenAPI.HTTPRequest.Sign.OSS4 do
  @moduledoc """
  A implementation for OSS V4 signature.

  Read more at:

    * [Object Storage Service > Developer Reference > Use the RESTful API to initiate requests](https://www.alibabacloud.com/help/en/oss/developer-reference/use-the-restful-api-to-initiate-requests/)
    * [Object Storage Service > Developer Reference > Use the RESTful API to initiate requests (zh-Hans)](https://www.alibabacloud.com/help/zh/oss/developer-reference/use-the-restful-api-to-initiate-requests/)

  """

  import CozyAliyunOpenAPI.Utils,
    only: [
      encode_rfc3986: 1,
      md5: 1,
      sha256: 1,
      hmac_sha256: 2,
      base16: 1,
      base64: 1
    ]

  alias CozyAliyunOpenAPI.Config
  alias CozyAliyunOpenAPI.EasyTime
  alias CozyAliyunOpenAPI.HTTPRequest
  alias CozyAliyunOpenAPI.HTTPRequest.Sign

  @signature_version "OSS4-HMAC-SHA256"
  @access_key_version "aliyun_v4"
  @request_version "aliyun_v4_request"
  @service_name "oss"

  @behaviour Sign

  @impl true
  def sign(request,
        type: type,
        at: %DateTime{} = at,
        config: %Config{} = config,
        region: region,
        bucket: bucket
      ) do
    datetime_in_rfc1123 = EasyTime.to_rfc1123(at)
    datetime_in_iso8601 = EasyTime.to_basic_iso8601(at)
    date_in_iso8601 = DateTime.to_date(at) |> EasyTime.to_basic_iso8601()

    ctx = %{
      type: type,
      config: config,
      region: String.trim_leading(region, "oss-"),
      bucket: bucket,
      datetime: datetime_in_iso8601,
      date: date_in_iso8601
    }

    request
    |> sanitize_headers!()
    |> HTTPRequest.put_header("host", request.host)
    |> HTTPRequest.put_header("date", datetime_in_rfc1123)
    |> put_signature(ctx)
  end

  defp sanitize_headers!(request) do
    Map.update!(request, :headers, fn headers ->
      Enum.into(headers, %{}, fn {k, v} ->
        {
          k |> Kernel.to_string() |> String.trim() |> String.downcase(),
          v |> Kernel.to_string() |> String.trim()
        }
      end)
    end)
  end

  defp put_signature(request, %{type: :header} = ctx) do
    %{datetime: datetime} = ctx

    request
    |> HTTPRequest.put_header_lazy("content-md5", &build_content_md5(&1))
    |> HTTPRequest.put_header_lazy("content-type", &detect_content_type(&1))
    |> HTTPRequest.put_header("x-oss-date", datetime)
    |> HTTPRequest.put_header("x-oss-content-sha256", build_hashed_payload(request))
    |> HTTPRequest.put_header("authorization", fn request ->
      additional_headers = build_additional_headers(request)

      content =
        [
          "Credential=#{build_credential(request, ctx)}",
          if(additional_headers != [], do: "AdditionalHeaders=#{additional_headers}", else: nil),
          "Signature=#{build_signature(request, ctx)}"
        ]
        |> Enum.reject(&(&1 == nil))
        |> Enum.join(",")

      "#{@signature_version} #{content}"
    end)
  end

  defp put_signature(request, %{type: :url} = ctx) do
    %{datetime: datetime} = ctx

    request
    |> HTTPRequest.put_query("x-oss-signature-version", @signature_version)
    |> HTTPRequest.put_query("x-oss-credential", build_credential(request, ctx))
    |> HTTPRequest.put_query("x-oss-date", datetime)
    |> HTTPRequest.put_query_lazy("x-oss-expires", fn _request -> 3600 end)
    |> HTTPRequest.put_query("x-oss-additional-headers", &build_additional_headers(&1))
    |> HTTPRequest.put_query("x-oss-signature", &build_signature(&1, ctx))
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

  defp build_credential(_request, ctx) do
    %{
      config: %{access_key_id: access_key_id},
      region: region,
      date: date
    } = ctx

    Enum.join([access_key_id, date, region, @service_name, @request_version], "/")
  end

  defp build_signature(request, ctx) do
    %{
      config: %{access_key_secret: access_key_secret},
      date: date,
      region: region
    } = ctx

    "#{@access_key_version}#{access_key_secret}"
    |> hmac_sha256(date)
    |> hmac_sha256(region)
    |> hmac_sha256(@service_name)
    |> hmac_sha256(@request_version)
    |> hmac_sha256(build_string_to_sign(request, ctx))
    |> base16()
  end

  defp build_string_to_sign(request, ctx) do
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
    request.method
    |> Atom.to_string()
    |> String.upcase()
  end

  defp build_canonical_path(request, ctx) do
    bucket = ctx.bucket
    path = request.path

    if(bucket,
      do: "/#{bucket}#{path}",
      else: path
    )
    |> URI.encode()
  end

  defp build_canonical_querystring(request) do
    request.query
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
