defmodule CozyAliyunOpenAPI.Config do
  @moduledoc """
  A struct representing a config.
  """

  @config_schema [
    access_key_id: [
      type: :string,
      required: true
    ],
    access_key_secret: [
      type: :string,
      required: true
    ]
  ]

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
  def new!(%{} = config) do
    config
    |> Map.to_list()
    |> NimbleOptions.validate!(@config_schema)
    |> then(&struct(__MODULE__, &1))
  end
end
