defmodule CozyAliyunOpenAPI.Config do
  @enforce_keys [:access_key_id, :access_key_secret]
  defstruct @enforce_keys

  @type config() :: %{
          access_key_id: String.t(),
          access_key_secret: String.t()
        }

  @type t :: %__MODULE__{
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
           access_key_id: access_key_id,
           access_key_secret: access_key_secret
         } = config
       )
       when is_binary(access_key_id) and
              is_binary(access_key_secret) do
    config
  end

  defp validate_required_keys!(_config) do
    raise ArgumentError,
          "key :access_key_id, :access_key_secret should be provided"
  end

  defp as_struct!(config) do
    default_struct = __MODULE__.__struct__()
    valid_keys = Map.keys(default_struct)
    config = Map.take(config, valid_keys)
    Map.merge(default_struct, config)
  end
end
