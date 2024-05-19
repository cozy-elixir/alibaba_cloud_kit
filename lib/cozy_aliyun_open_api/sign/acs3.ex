defmodule CozyAliyunOpenAPI.Sign.ACS3 do
  @moduledoc """
  A implementation for ACS V3 signature.

  Read more at:

    * [Alibaba Cloud SDK > Product Overview > Request syntax and signature method V3](https://www.alibabacloud.com/help/en/sdk/product-overview/v3-request-structure-and-signature)
    * [Alibaba Cloud SDK > Product Overview > Request syntax and signature method V3 (zh-Hans)](https://www.alibabacloud.com/help/zh/sdk/product-overview/v3-request-structure-and-signature)

  """

  import CozyAliyunOpenAPI.Utils,
    only: [
      random_string: 0,
      sha256: 1,
      hmac_sha256: 2,
      base16: 1
    ]

  alias CozyAliyunOpenAPI.Config
  alias CozyAliyunOpenAPI.EasyTime
  alias CozyAliyunOpenAPI.HTTPRequest
  alias CozyAliyunOpenAPI.Sign

  @signature_version "ACS3-HMAC-SHA256"

  @behaviour Sign

  @impl true
  def sign(%HTTPRequest{} = request, at: %DateTime{} = at, config: %Config{} = config) do
    datetime = EasyTime.to_extended_iso8601(at)

    request
    |> sanitize_headers!()
    |> HTTPRequest.put_header("host", request.host)
    |> HTTPRequest.put_header("x-acs-date", datetime)
    |> HTTPRequest.put_header("x-acs-content-sha256", build_hashed_payload(request))
    |> HTTPRequest.put_new_header("x-acs-signature-nonce", fn _request -> random_string() end)
    |> HTTPRequest.put_header("authorization", fn request ->
      build_authorization(request, config)
    end)
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

  defp build_authorization(request, config) do
    credential = config.access_key_id
    signed_headers = build_signed_headers(request)
    signature = build_signature(request, config.access_key_secret)

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
    request.method
    |> Atom.to_string()
    |> String.upcase()
  end

  defp build_canonical_path(request) do
    request.path
    |> URI.encode()
  end

  defp build_canonical_querystring(request) do
    request.query
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
