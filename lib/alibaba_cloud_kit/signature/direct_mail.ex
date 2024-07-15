defmodule AlibabaCloudKit.Signature.DirectMail do
  @moduledoc """
  An implementation for DirectMail signature.

  > I don't know the exact name of this type of signature, so let's call it
  > DirectMail for now.

  This type of signature is used by:

     * Direct Mail (DM)

  Read more at:

    * [Direct Mail > API Reference > Call Method](https://www.alibabacloud.com/help/en/direct-mail/call-method/)
    * [邮件推送 > API 参考 > 调用方式](https://help.aliyun.com/zh/direct-mail/call-method/)

  """

  import AlibabaCloudKit.Utils,
    only: [
      utc_now: 1,
      to_extended_iso8601: 1,
      random_string: 0,
      hmac_sha1: 2,
      base64: 1,
      encode_rfc3986: 1
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

  @doc """
  Signs a request.

  ## Automatically added params

  Following params will be added to the request automatically:

    * `AccessKeyId`
    * `SignatureMethod`
    * `SignatureVersion`
    * `SignatureNonce`
    * `Signature`
    * `Timestamp`

  For GET requests, they will be added to query. For POST requests, they will be
  added to body.

  ## Examples

  ### Build and sign a GET request

      params = %{
        "Format" => "JSON",
        "Version" => "2015-11-23",
        "Action" => "SingleSendMail",
        "AccountName" => "admin@alibabacloudkit.com",
        "AddressType" => "1",
        "ReplyToAddress" => "false",
        "FromAlias" => "AlibabaCloudKit Group",
        "Subject" => "Announcement of AlibabaCloudKit",
        "ToAddress" => "test@user.com",
        "TextBody" => "This is the email send by AlibabaCloudKit."
      }

      opts = [
        access_key_id: "access_key_id",
        access_key_secret: "access_key_secret"
      ]

      HTTPSpec.Request.new!(
        method: :get,
        scheme: :https,
        host: "dm.aliyuncs.com",
        port: 443,
        path: "/",
        query: URI.encode_query(params, :rfc3986)
      )
      |> AlibabaCloudKit.Signature.DirectMail.sign!(opts)

  ### Build and sign a POST request

      params = %{
        "Format" => "JSON",
        "Version" => "2015-11-23",
        "Action" => "SingleSendMail",
        "AccountName" => "admin@alibabacloudkit.com",
        "AddressType" => "1",
        "ReplyToAddress" => "false",
        "FromAlias" => "AlibabaCloudKit Group",
        "Subject" => "Announcement of AlibabaCloudKit",
        "ToAddress" => "test@user.com",
        "TextBody" => "This is the email send by AlibabaCloudKit."
      }

      opts = [
        access_key_id: "access_key_id",
        access_key_secret: "access_key_secret"
      ]

      HTTPSpec.Request.new!(
        method: :post,
        scheme: :https,
        host: "dm.aliyuncs.com",
        port: 443,
        path: "/",
        headers: [
          {"content-type", "application/x-www-form-urlencoded"}
        ],
        body: URI.encode_query(params, :www_form)
      )
      |> AlibabaCloudKit.Signature.DirectMail.sign!(opts)

  """
  @spec sign!(Request.t(), sign_opts()) :: Request.t()
  def sign!(%Request{} = request, opts) when is_list(opts) do
    opts =
      opts
      |> NimbleOptions.validate!(@sign_opts_definition)
      |> Map.new()

    %{
      access_key_id: access_key_id,
      access_key_secret: access_key_secret,
      at: at
    } = opts

    at = at || utc_now(:second)

    default_params = %{
      "AccessKeyId" => access_key_id,
      "SignatureMethod" => "HMAC-SHA1",
      "SignatureVersion" => "1.0",
      "SignatureNonce" => random_string(),
      "Timestamp" => to_extended_iso8601(at)
    }

    request
    |> put_default_params(default_params)
    |> put_signature(access_key_secret)
  end

  defp put_default_params(%Request{method: :get} = request, default_params) do
    params = URI.decode_query(request.query, %{}, :rfc3986)
    query = default_params |> Map.merge(params) |> URI.encode_query(:rfc3986)
    %{request | query: query}
  end

  defp put_default_params(%Request{method: :post} = request, default_params) do
    params = URI.decode_query(request.body, %{}, :www_form)
    body = default_params |> Map.merge(params) |> URI.encode_query(:www_form)
    %{request | body: body}
  end

  defp put_signature(%Request{method: :get} = request, access_key_secret) do
    signature = build_signature(request, access_key_secret)

    query =
      request.query
      |> URI.decode_query(%{}, :rfc3986)
      |> Map.put("Signature", signature)
      |> URI.encode_query(:rfc3986)

    %{request | query: query}
  end

  defp put_signature(%Request{method: :post} = request, access_key_secret) do
    signature = build_signature(request, access_key_secret)

    body =
      request.body
      |> URI.decode_query(%{}, :www_form)
      |> Map.put("Signature", signature)
      |> URI.encode_query(:www_form)

    %{request | body: body}
  end

  defp build_signature(request, secret) do
    "#{secret}&"
    |> hmac_sha1(build_string_to_sign(request))
    |> base64()
  end

  defp build_string_to_sign(request) do
    [
      build_canonical_method(request),
      build_canonical_path(request),
      build_canonical_params(request)
    ]
    |> Enum.map_join("&", &encode_rfc3986/1)
  end

  defp build_canonical_method(request) do
    Request.build_method(request)
  end

  defp build_canonical_path(request) do
    request.path
  end

  defp build_canonical_params(%Request{method: :get} = request) do
    request.query
    |> URI.decode_query(%{}, :rfc3986)
    |> Enum.sort()
    |> URI.encode_query(:rfc3986)
  end

  defp build_canonical_params(%Request{method: :post} = request) do
    request.body
    |> URI.decode_query(%{}, :www_form)
    |> Enum.sort()
    |> URI.encode_query(:rfc3986)
  end
end
