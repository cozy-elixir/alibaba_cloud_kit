defmodule AliyunOpenAPI.HTTP.ClientTest do
  use ExUnit.Case
  alias AliyunOpenAPI.HTTP.Request
  alias AliyunOpenAPI.HTTP.Client

  test "creates and requests an HTTP request" do
    assert {:ok, %{status: 200}} =
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
