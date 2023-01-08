defmodule CozyAliyunOpenAPI.Config do
  @enforce_keys [:endpoint, :access_key_id, :access_key_secret]
  defstruct @enforce_keys

  @typedoc """
  The endpoint of an API calling.

  ## Supported formats

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
  @type endpoint() :: String.t()

  @type config() :: %{
          endpoint: endpoint(),
          access_key_id: String.t(),
          access_key_secret: String.t()
        }

  @type t :: %__MODULE__{
          endpoint: endpoint(),
          access_key_id: String.t(),
          access_key_secret: String.t()
        }

  @spec new!(config()) :: t()
  def new!(config) when is_map(config) do
    config
    |> validate_required_keys!()
    |> as_struct!()
  end

  defp validate_required_keys!(
         %{
           endpoint: endpoint,
           access_key_id: access_key_id,
           access_key_secret: access_key_secret
         } = config
       )
       when is_binary(endpoint) and
              is_binary(access_key_id) and
              is_binary(access_key_secret) do
    config
  end

  defp validate_required_keys!(_config) do
    raise ArgumentError,
          "config :endpoint, :access_key_id, :access_key_secret are required"
  end

  defp as_struct!(config) do
    default_struct = __MODULE__.__struct__()
    valid_keys = Map.keys(default_struct)
    config = Map.take(config, valid_keys)
    Map.merge(default_struct, config)
  end
end
