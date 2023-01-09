defmodule CozyAliyunOpenAPI.Specs.OSS do
  @moduledoc """
  Describes an OSS style API.

  Read more at
  [对象存储 OSS > 开发指南 > 使用REST API发起请求](https://help.aliyun.com/document_detail/375302.html).
  """

  alias CozyAliyunOpenAPI.Config

  defstruct []

  @type t :: %__MODULE__{}

  @spec new!(Config.t(), map()) :: t()
  def new!(%Config{} = _config, %{} = _spec_config) do
    raise RuntimeError, "OSS style API is not supported for now"
  end
end
