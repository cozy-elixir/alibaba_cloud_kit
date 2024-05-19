defprotocol CozyAliyunOpenAPI.Sign do
  @moduledoc """
  The protocol for signing a target.
  """

  @doc """
  Signs a target.
  """
  @spec sign(any(), keyword()) :: any()
  def sign(target, env)
end
