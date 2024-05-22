defmodule CozyAliyunOpenAPI do
  @moduledoc ~s"""
  An SDK builder for Aliyun / Alibaba Cloud OpenAPI.

  ## Basic concepts

  An API call will go through the following steps:

  1. creating a config.
  2. creating a spec.
  3. transforming the spec to a HTTP request.
  4. sending the HTTP request.

  ## Quick start

  Add necessary packages:

      {:cozy_aliyun_open_api, "~> 0.4"},
      {:finch, "~> 0.18"},
      {:sax_map, "~> 1.0"},

  Start a Finch child in your supervision tree:

      children = [
        {Finch, name: CozyAliyunOpenAPI.Finch}
      ]

  Make a request:

      alias CozyAliyunOpenAPI.Config
      alias CozyAliyunOpenAPI.Specs.RPC
      alias CozyAliyunOpenAPI.HTTP.Request
      alias CozyAliyunOpenAPI.HTTP.Client

      # 1. create a config
      config =
        Config.new!(
          access_key_id: "...",
          access_key_secret: "..."
        )

      # 2. create a spec
      RPC.new!(config,
        method: :post,
        endpoint: "https://ecs-cn-hangzhou.aliyuncs.com/",
        shared_params: %{
          "Action" => "DescribeInstanceStatus",
          "Version" => "2014-05-26"
        },
        params: %{
          "RegionId" => "cn-hangzhou"
        }
      )
      # 3. transform the spec to a HTTP request
      |> Request.from_spec!()
      # 4. send the HTTP request
      |> Client.request()

  > In order to accommodate as many different usage scenarios as possible,
  > `#{inspect(__MODULE__)}` provides only low-level APIs.
  >
  > If you find the API calls are tedious, consider to encapsulate the low-level
  > APIs by yourself. There are some examples in the `/examples` directory for
  > reference.

  ## API styles

  For a variety of reasons, Aliyun OpenAPI involves several different API styles:

  * RPC
  * ROA
  * OSS

  These different styles of APIs are supported by different spec modules:

  * `CozyAliyunOpenAPI.Specs.RPC`
  * `CozyAliyunOpenAPI.Specs.ROA`
  * `CozyAliyunOpenAPI.Specs.OSS`

  > Q: Which spec should I use?
  >
  > A: First, you should check the style of the API you wanna use.
  > See next section for more.

  ## Check the styles of APIs

  1. View the API style of a cloud service in the **List of operations by function**
     topic of the API Reference for the service.
  2. Search for the API of a cloud service in [OpenAPI Explorer](https://next.api.alibabacloud.com/). In the API
     Debugging module, check the SDK sample code:
     * If the sample code involves writing parameters to headers, the API is in the ROA style.
     * Otherwise, the API is in the RPC style.

  ## About endpoints

  In official docs, the term *endpoint* refers to different things:

  * sometimes, it refers to a host, such as `ecs-cn-hangzhou.aliyuncs.com`.
  * sometimes, it refers to a URL, such as `https://ecs-cn-hangzhou.aliyuncs.com`.

  This kind of inconsistency is annoying.

  `#{inspect(__MODULE__)}` will **always** use the term *endpoint* to refer to a base URL:

      <protocol>://<host>/<path>

  ### Public endpoints

  * centralized deployments: `<protocol>://<service_code>.aliyuncs.com/`
  * multi-region deployments: `<protocol>://<service_code>.<region_id>.aliyuncs.com/`

  ### private endpoints (aka VPC endpoints)

  Private endpoints are also known as VPC endpoints.

  * centralized deployments: `<protocol>://<service_code>.vpc-proxy.aliyuncs.com/`
  * multi-region deployments: `<protocol>://<service_code>-vpc.<region_id>.aliyuncs.com/`

  ### Public endpoints vs. Private endpoints

  Public endpoints consume public network traffic.

  Private endpoints don't consume public network traffic. In addition, they provide higher network
  speed, and higher level secure protection.

  Personally, I recommend using private endpoints as much as possible.

  ## Authentication

  ### Required credentials

  Required credentials can be a combination of the following data:

  * Access Key ID
  * Access Key Secret
  * STS Token

  > STS is the shorthand for Security Token Service. It allows developers to manage temporary
  > credentials to resources.

  Please make sure that you have got the right ones.

  ### Signature mechanisms

  Different API styles use different signature mechanisms.

  The `CozyAliyunOpenAPI.Specs.*` modules will try their best to include relevant
  implementations. You don't have to implement these yourself.

  ## Authorization

  Before calling any API, please make sure that the required permission is granted.

  """
end
