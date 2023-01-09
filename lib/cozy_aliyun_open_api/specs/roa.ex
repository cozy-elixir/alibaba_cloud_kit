defmodule CozyAliyunOpenAPI.Specs.ROA do
  @moduledoc """
  Describes an ROA style API.

  Read more at
  [阿里云 SDK > 调用机制 > ROA 调用机制](https://help.aliyun.com/document_detail/315525.html).
  """

  alias CozyAliyunOpenAPI.Config

  defstruct []

  @type t :: %__MODULE__{}

  @spec new!(Config.t(), map()) :: t()
  def new!(%Config{} = _config, %{} = _spec_config) do
    raise RuntimeError, "ROA style API is not supported for now"
  end
end
