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

  describe "request/1" do
    # comment it for now, because https://httpbin.org is returning an XML using us-ascii encoding,
    # which is not supported by Saxy for now.
    #
    # test "converts XML body as a map" do
    #   assert {:ok, 200, _, _} =
    #            %{
    #              scheme: "https",
    #              host: "httpbin.org",
    #              port: 443,
    #              method: :get,
    #              path: "/xml"
    #            }
    #            |> HTTPRequest.new!()
    #            |> HTTPClient.request()
    # end

    test "converts JSON body as a map" do
      assert {:ok, 200, _, %{}} =
               %{
                 scheme: "https",
                 host: "httpbin.org",
                 port: 443,
                 method: :get,
                 path: "/json"
               }
               |> HTTPRequest.new!()
               |> HTTPClient.request()
    end
  end
end
