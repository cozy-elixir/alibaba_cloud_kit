defmodule AlibabaCloudKit do
  @moduledoc ~s"""
  A kit for Alibaba Cloud or Aliyun.

  Note that this is not a one-stop, comprehensive SDK. As the name implies, it
  is a kit for building your own minimalistic and focused SDK.

    * Read more about this idea at [Ship utilities for building platform SDKs](https://github.com/cozy-elixir/proposals/blob/main/ship-utilities-for-building-platform-sdks.md).
    * See examples at `examples/` directory in the source code.

  Following are a few things worth knowing before you start.

  ## What does this package provides?

  Currently, this package mainly provides:

    * signature helpers - `AlibabaCloudKit.Signature.*`

  ## API styles

  For a variety of reasons, Alibaba Cloud involves several different API styles:

    * RPC
      * Elastic Compute Service (ECS)
      * Content Delivery Network (CDN)
      * ApsaraDB RDS
      * ...
    * ROA
      * Application Real-Time Monitoring Service (ARMS)
      * Batch Compute, Container Service for Kubernetes (ACK)
      * Elasticsearch
      * ...
    * OSS
      * Object Storage Service (OSS)

  The requests of RPC-style API can be signed by `AlibabaCloudKit.Signature.ACS3`.
  The requests of OSS-style API can be signed by `AlibabaCloudKit.Signature.OSS4`.

  > Personally, I don't have the need for ROA-style API for now. So, related
  > signature helper isn't provided. PRs are welcome.

  ## Check the style of an API

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

  ## Build and send an API request

  Despite the diversity of API styles, their request flow is consistent:

    1. build a request according to the official docs. (by [http_spec](https://hex.pm/packages/http_spec))
    2. sign the request. (**this package helps to do it**)
    3. send the request via your preferred HTTP client. (in your application code)
    4. process the response. (in your application code)

  ## Authorization

  Before calling any API, please make sure that the required permission is granted.

  ## About endpoints

  In official docs, the term *endpoint* refers to different things:

  * sometimes, it refers to a host, such as `ecs.us-west-1.aliyuncs.com`.
  * sometimes, it refers to a URL, such as `https://ecs.use-west-1.aliyuncs.com`.

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
