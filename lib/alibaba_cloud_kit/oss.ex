defmodule AlibabaCloudKit.OSS do
  @moduledoc """
  A kit for OSS style API.

  Read more at:

    * [Object Storage Service > Developer Reference > Developer Guide > Use the RESTful API to initiate requests](https://www.alibabacloud.com/help/en/oss/developer-reference/use-the-restful-api-to-initiate-requests/)
    * [对象存储 > 开发参考 > 开发指南 > 使用 REST API 发起请求](https://help.aliyun.com/zh/oss/developer-reference/use-the-restful-api-to-initiate-requests/)

  ## The base URL

  Following formats can be used:

    * region URL, such as `https://oss-us-west-1.aliyuncs.com`.
    * virtual-hosted style URL, such as `https://example-bucket.oss-us-west-1.aliyuncs.com`.
    * custom domain name, such as `https://www.example.com`.
    * ...

  ## Adding signature

  This implementation has built-in OSS4 signature support, and it's controlled
  by the `:sign_type` option:

    * `:header` - add signature to the headers of a request.
    * `:query` - add signature to the query of a request.

  > V1 signature is not supported.

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


      AlibabaCloudKit.OSS.sign_request!(request, opts)

  ### Build a pre-signed url for `GetObject` operation

      request = HTTPSpec.Request.new!(
        method: :get,
        scheme: :https,
        host: "example-bucket.oss-us-west-1.aliyuncs.com",
        port: 443,
        path: "/example-object",
        headers: [
          {"x-oss-expires", "900"}
        ]
      )

      opts = [
        access_key_id: "...",
        access_key_secret: "...",
        region: "oss-us-west-1",
        bucket: "example-bucket",
        sign_type: :query
      ]

      request
      |> AlibabaCloudKit.OSS.sign_request!(opts)
      |> HTTPSpec.Request.build_url()

  """

  alias HTTPSpec.Request
  alias AlibabaCloudKit.Signature

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

  @doc """
  Signs a request with OSS4 signature.
  """
  @spec sign_request!(Request.t(), sign_opts()) :: Request.t()
  def sign_request!(%Request{} = request, opts) do
    opts =
      opts
      |> NimbleOptions.validate!(@sign_opts_definition)
      |> Map.new()

    Signature.OSS4.sign(request, opts)
  end
end
