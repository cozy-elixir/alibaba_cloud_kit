defmodule CozyAliyunOpenAPI.Specs.RPCTest do
  use ExUnit.Case

  alias CozyAliyunOpenAPI.Config
  alias CozyAliyunOpenAPI.Specs.RPC
  alias CozyAliyunOpenAPI.HTTPRequest
  alias CozyAliyunOpenAPI.HTTPClient

  setup do
    config =
      Config.new!(%{
        access_key_id: System.fetch_env!("OSS_ACCESS_KEY_ID"),
        access_key_secret: System.fetch_env!("OSS_ACCESS_KEY_SECRET")
      })

    %{config: config}
  end

  describe "Turning an RPC spec as an HTTP request" do
    test "works for GET method", %{config: config} do
      assert {:ok, 200, _header, _body} =
               RPC.new!(config, %{
                 endpoint: "https://ecs-cn-hangzhou.aliyuncs.com/",
                 method: :get,
                 version: "2014-05-26",
                 action: "DescribeInstanceStatus",
                 params: %{"RegionId" => "cn-hangzhou"}
               })
               |> HTTPRequest.from_spec!()
               |> HTTPClient.request()
    end

    test "works for POST method", %{config: config} do
      assert {:ok, 200, _header, _body} =
               RPC.new!(config, %{
                 endpoint: "https://ecs-cn-hangzhou.aliyuncs.com/",
                 method: :post,
                 version: "2014-05-26",
                 action: "DescribeInstanceStatus",
                 params: %{"RegionId" => "cn-hangzhou"}
               })
               |> HTTPRequest.from_spec!()
               |> HTTPClient.request()
    end
  end
end
