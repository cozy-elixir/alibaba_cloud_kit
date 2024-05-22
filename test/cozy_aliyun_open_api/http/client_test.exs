defmodule CozyAliyunOpenAPI.HTTP.ClientTest do
  use ExUnit.Case
  alias CozyAliyunOpenAPI.HTTP.Request
  alias CozyAliyunOpenAPI.HTTP.Client

  test "creates and requests an HTTP request" do
    assert {:ok, 200, _, _} =
             %{
               scheme: "https",
               host: "httpbin.org",
               port: 443,
               method: :get,
               path: "/headers"
             }
             |> Request.new!()
             |> Client.request()
  end
end
