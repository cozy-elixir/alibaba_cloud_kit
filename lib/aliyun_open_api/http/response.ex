defmodule AliyunOpenAPI.HTTP.Response do
  @moduledoc """
  A struct representing an HTTP response.
  """

  @enforce_keys [
    :status,
    :headers,
    :body
  ]

  defstruct @enforce_keys

  @type status :: pos_integer()
  @type headers :: [{String.t(), String.t()}]
  @type body :: iodata()

  @type t :: %__MODULE__{
          status: status(),
          headers: headers(),
          body: body()
        }
end
