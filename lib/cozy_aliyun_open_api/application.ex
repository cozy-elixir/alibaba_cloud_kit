defmodule CozyAliyunOpenAPI.Application do
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    CozyAliyunOpenAPI.HTTP.Client.init()

    children = []

    opts = [strategy: :one_for_one, name: CozyAliyunOpenAPI.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
