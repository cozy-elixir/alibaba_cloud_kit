defmodule CozyAliyunOpenAPI do
  @moduledoc """
  An SDK builder for Aliyun OpenAPI.

  ## API Styles

  For a variety of reasons, Aliyun OpenAPI involves several different API styles:

  * RPC
  * ROA
  * OSS

  ## Authentication & Authorization

  ### Required credentials

  Authentication can be accomplished in two ways. Different ways require different credentials:

  * Access Key ID / Access Key Secret
  * Access Key ID / Access Key Secret / STS Token

  > STS is the shorthand for Security Token Service. It allows developers to manage temporary
  > credentials to resources.

  ### Signature mechanism

  When using the credentials, the Access Key Secret shouldn't be sent. Intead, signatures generated
  in some way should be used.

  Different API styles use different signature mechanisms. The `CozyAliyunOpenAPI.Specs.*` modules
  will try their best to include relevant implementations.

  ### Authorization

  Before calling any API, please make sure the required permission is granted.

  ## Endpoints

  ### Public endpoints

  * centralized deployments: `<service code>.aliyuncs.com`
  * multi-region deployments: `<service code>.<region id>.aliyuncs.com`

  ### Private endpoints (aka VPC endpoints)

  Private endpoints are also known as VPC endpoints.

  * centralized deployments: `<service code>.vpc-proxy.aliyuncs.com`
  * multi-region deployments: `<service code>-vpc.<region id>.aliyuncs.com`

  ### Public endpoints vs. Private endpoints

  Public endpoints consume public network traffic.

  Private endpoints don't consume public network traffic. In addition, they provide higher network
  speed, and higher level secure protection.

  Personally, I recommend using private endpoints as much as possible.

  """

  @doc """
  Hello world.

  ## Examples

      iex> CozyAliyunOpenAPI.hello()
      :world

  """
  def hello do
    :world
  end
end
