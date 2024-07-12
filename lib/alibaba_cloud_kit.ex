defmodule AlibabaCloudKit do
  @moduledoc ~s"""
  A kit for Alibaba Cloud or Aliyun.

  > This package is built by following my proposal -
  > [Ship utilities for building platform SDKs](https://github.com/cozy-elixir/proposals/blob/main/ship-utilities-for-building-platform-sdks.md).

  ## API styles

  For a variety of reasons, Aliyun OpenAPI involves several different API styles:

  * RPC
  * ROA
  * OSS

  These different API styles are supported by different modules:

  * `AlibabaCloudKit.RPC`
  * `AlibabaCloudKit.ROA`
  * `AlibabaCloudKit.OSS`

  > Q: Which style should I use?
  >
  > A: You should check the API style by yourself. See next section for more.

  ## Check API style

  1. Visit [OpenAPI Explorer](https://next.api.alibabacloud.com/).
  2. Search the API you wanna use.
  3. Check the metadata, and the the metadata should like this:

  ```json
  {
    "version": "1.0",
    "info": {
       "version": "2014-05-26",
       "style": "RPC",  # <- This is the API style.
       "product": "Ecs"
    },
    // ...
  }
  ```

  ## Authentication

  Different styles of API use different signature mechanisms to authenticate an
  API request.

  The `AlibabaCloudKit.*` modules will try their best to provide relevant helpers.

  ## Authorization

  Before calling any API, please make sure that the required permission is granted.

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

  """
end
