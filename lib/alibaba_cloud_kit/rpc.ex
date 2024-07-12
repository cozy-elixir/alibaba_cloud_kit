defmodule AlibabaCloudKit.RPC do
  @moduledoc """
  A kit for RPC style API.

  APIs in the RPC style include:

    * Elastic Compute Service (ECS)
    * Content Delivery Network (CDN)
    * ApsaraDB RDS
    * ...

  Read more at:

    * [Alibaba Cloud SDK > Product Overview > Request syntax and signature method](https://www.alibabacloud.com/help/en/sdk/product-overview/request-structure-and-signature/)
    * [阿里云 SDK > 产品概述 > 请求结构和签名机制](https://help.aliyun.com/zh/sdk/product-overview/request-structure-and-signature/)

  ## Examples

  ### Build and sign a GET request

      request = HTTPSpec.Request.new!(
        method: :get,
        scheme: :https,
        host: "ecs-us-west-1.aliyuncs.com",
        port: 443,
        path: "/",
        query: URI.encode_query(%{"RegionId" => "us-west-1"}, :www_form),
        headers: [
          {"x-acs-version", "2014-05-26"},
          {"x-acs-action", "DescribeInstanceStatus"}
        ]
      )

      opts = [
        access_key_id: "...",
        access_key_secret: "..."
      ]

      AlibabaCloudKit.RPC.sign_request!(request, opts)

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

      AlibabaCloudKit.RPC.sign_request!(request, opts)

  """

  alias HTTPSpec.Request
  alias AlibabaCloudKit.Signature

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
  Signs a request with ACS3 signature.
  """
  def sign_request!(%Request{} = request, opts) do
    opts =
      opts
      |> NimbleOptions.validate!(@sign_opts_definition)
      |> Map.new()

    Signature.ACS3.sign(request, opts)
  end
end
