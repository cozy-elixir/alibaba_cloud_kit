defmodule CozyAliyunOpenAPI do
  @moduledoc ~s"""
  An SDK builder for Aliyun OpenAPI.

  ## Basic Concepts

  A complete API call will go through the following steps:

  1. creating a config.
  2. creating a spec.
  3. transforming the spec to a HTTP request.
  4. sending the HTTP request.

  ## A Code Example

      alias CozyAliyunOpenAPI.Config
      alias CozyAliyunOpenAPI.Specs.RPC
      alias CozyAliyunOpenAPI.HTTPRequest
      alias CozyAliyunOpenAPI.HTTPClient

      # 1. create a config
      config =
        Config.new!(%{
          access_key_id: "...",
          access_key_secret: "..."
        })

      # 2. create a spec
      RPC.new!(config, %{
        method: :post,
        endpoint: "https://ecs-cn-hangzhou.aliyuncs.com/",
        shared_params: %{
          "Action" => "DescribeInstanceStatus",
          "Version" => "2014-05-26"
        },
        params: %{
          "RegionId" => "cn-hangzhou"
        }
      })
      # 3. transform the spec to a HTTP request
      |> HTTPRequest.from_spec!()
      # 4. send the HTTP request
      |> HTTPClient.request()

  > In order to accommodate as many different usage scenarios as possible, `#{inspect(__MODULE__)}`
  > provides only low-level APIs.
  >
  > If you find the API calls are tedious, consider to encapsulate the low-level APIs by yourself.

  ## API Styles

  For a variety of reasons, Aliyun OpenAPI involves several different API styles:

  * RPC
  * ROA
  * OSS

  These different styles of APIs are supported by different spec modules:

  * `CozyAliyunOpenAPI.Specs.RPC`
  * `CozyAliyunOpenAPI.Specs.ROA`
  * `CozyAliyunOpenAPI.Specs.OSS`

  ## Authentication & Authorization

  ### required credentials

  Authentication can be accomplished in two ways. Different ways require different credentials:

  * Access Key ID / Access Key Secret
  * Access Key ID / Access Key Secret / STS Token

  > STS is the shorthand for Security Token Service. It allows developers to manage temporary
  > credentials to resources.

  ### signature mechanisms

  When using the credentials, the Access Key Secret shouldn't be sent. Intead, signatures generated
  in a certain way should be used.

  Different API styles use different signature mechanisms. The `CozyAliyunOpenAPI.Specs.*` modules
  will try their best to include relevant implementations.

  ### authorization

  Before calling any API, please make sure the required permission is granted.

  ## About Endpoints

  In official docs, the term *endpoint* refers to different things:

  * sometimes, it refers to a host, such as `ecs-cn-hangzhou.aliyuncs.com`.
  * sometimes, it refers to a URL, such as `https://ecs-cn-hangzhou.aliyuncs.com`.

  That is annoying.

  `#{inspect(__MODULE__)}` will always use the endpoint to refer to a valid URL:

      <protocol>://<host>/<path>?<query>

  ### public endpoints

  * centralized deployments: `<protocol>://<service_code>.aliyuncs.com/`
  * multi-region deployments: `<protocol>://<service_code>.<region_id>.aliyuncs.com/`

  ### private endpoints (aka VPC endpoints)

  Private endpoints are also known as VPC endpoints.

  * centralized deployments: `<protocol>://<service_code>.vpc-proxy.aliyuncs.com/`
  * multi-region deployments: `<protocol>://<service_code>-vpc.<region_id>.aliyuncs.com/`

  ### public endpoints vs. private endpoints

  Public endpoints consume public network traffic.

  Private endpoints don't consume public network traffic. In addition, they provide higher network
  speed, and higher level secure protection.

  Personally, I recommend using private endpoints as much as possible.

  """

  @doc false
  def json_library, do: Application.fetch_env!(:cozy_aliyun_open_api, :json_library)
end
