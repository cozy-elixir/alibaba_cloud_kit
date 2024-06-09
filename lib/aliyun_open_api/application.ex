defmodule AliyunOpenAPI.Application do
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    AliyunOpenAPI.HTTP.Client.init()

    children = []

    opts = [strategy: :one_for_one, name: AliyunOpenAPI.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
