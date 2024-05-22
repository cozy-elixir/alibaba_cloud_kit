defmodule CozyAliyunOpenAPI.Specs.RPCTest do
  use ExUnit.Case

  alias CozyAliyunOpenAPI.Config
  alias CozyAliyunOpenAPI.Specs.RPC
  alias CozyAliyunOpenAPI.HTTP.Request
  alias CozyAliyunOpenAPI.HTTP.Client

  setup do
    config =
      Config.new!(
        access_key_id: System.fetch_env!("TEST_ACCESS_KEY_ID"),
        access_key_secret: System.fetch_env!("TEST_ACCESS_KEY_SECRET")
      )

    %{config: config}
  end

  describe "Turning an RPC spec as an HTTP request" do
    test "works for GET method", %{config: config} do
      assert {:ok, %{status: 200}} =
               RPC.new!(config,
                 endpoint: "https://ecs-cn-hangzhou.aliyuncs.com/",
                 method: :get,
                 version: "2014-05-26",
                 action: "DescribeInstanceStatus",
                 params: %{"RegionId" => "cn-hangzhou"}
               )
               |> Request.from_spec!()
               |> Client.request()
    end

    test "works for POST method", %{config: config} do
      assert {:ok, %{status: 200}} =
               RPC.new!(config,
                 endpoint: "https://ecs-cn-hangzhou.aliyuncs.com/",
                 method: :post,
                 version: "2014-05-26",
                 action: "DescribeInstanceStatus",
                 params: %{"RegionId" => "cn-hangzhou"}
               )
               |> Request.from_spec!()
               |> Client.request()
    end
  end
end
