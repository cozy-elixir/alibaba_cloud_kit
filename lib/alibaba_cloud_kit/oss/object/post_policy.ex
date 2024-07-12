defmodule AlibabaCloudKit.OSS.Object.PostPolicy do
  @moduledoc false

  @enforce_keys [:expiration, :conditions]
  defstruct @enforce_keys
end
