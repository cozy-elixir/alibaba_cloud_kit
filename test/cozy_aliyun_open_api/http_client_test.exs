defmodule CozyAliyunOpenAPI.HTTPClientTest do
  use ExUnit.Case
  alias CozyAliyunOpenAPI.HTTPRequest
  alias CozyAliyunOpenAPI.HTTPClient

  describe "new!/2" do
    test "creates an HTTP request struct" do
      assert {:ok, 200, _, _} =
               %{
                 scheme: "https",
                 host: "httpbin.org",
                 port: 443,
                 method: :get,
                 path: "/headers"
               }
               |> HTTPRequest.new!()
               |> HTTPClient.request()
    end
  end
end
