defmodule CozyAliyunOpenAPI.Specs.ROA do
  @moduledoc """
  Describes an ROA style API.

  Read more at:

    * [Alibaba Cloud SDK > Product Overview > Request syntax and signature method](https://www.alibabacloud.com/help/en/sdk/product-overview/request-structure-and-signature/)
    * [Alibaba Cloud SDK > Product Overview > Request syntax and signature method (zh-Hans)](https://help.aliyun.com/zh/sdk/product-overview/request-structure-and-signature/)

  """

  alias CozyAliyunOpenAPI.Config

  defstruct []

  @type t :: %__MODULE__{}

  @spec new!(Config.t(), map()) :: t()
  def new!(%Config{} = _config, %{} = _spec_config) do
    raise RuntimeError, "ROA style API is not supported for now"
  end
end
