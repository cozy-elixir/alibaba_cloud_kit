defmodule CozyAliyunOpenAPI.Specs.ROA do
  @moduledoc """
  Describes an ROA style API.

  > ROA is a resource-oriented architectural style and an extension of
  > the REST style.

  APIs in the RPC style include:

    * Application Real-Time Monitoring Service (ARMS)
    * Batch Compute, Container Service for Kubernetes (ACK)
    * Elasticsearch
    * ...

  """

  alias CozyAliyunOpenAPI.Config

  defstruct []

  @type t :: %__MODULE__{}

  @spec new!(Config.t(), map()) :: t()
  def new!(%Config{} = _config, %{} = _spec_opts) do
    raise RuntimeError, "ROA style API is not supported for now"
  end
end
