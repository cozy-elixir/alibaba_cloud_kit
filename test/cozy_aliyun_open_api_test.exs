defmodule CozyAliyunOpenAPITest do
  use ExUnit.Case
  doctest CozyAliyunOpenAPI

  alias CozyAliyunOpenAPI.Config
  alias CozyAliyunOpenAPI.Specs.RPC
  alias CozyAliyunOpenAPI.HTTPRequest
  alias CozyAliyunOpenAPI.HTTPClient

  setup do
    config =
      Config.new!(%{
        access_key_id: System.fetch_env!("TEST_ACCESS_KEY_ID"),
        access_key_secret: System.fetch_env!("TEST_ACCESS_KEY_SECRET")
      })

    [config: config]
  end

  describe "use these modules" do
    test "for requesting an RPC style API", %{config: config} do
      assert {:ok, 200, _, %{}} =
               RPC.new!(config, %{
                 method: :post,
                 endpoint: "https://ecs-cn-hangzhou.aliyuncs.com/",
                 shared_params: %{
                   "Action" => "DescribeInstanceStatus",
                   "Version" => "2014-05-26"
                 },
                 params: %{
                   "RegionId" => "cn-hangzhou"
                 }
               })
               |> HTTPRequest.from_spec!()
               |> HTTPClient.request()
    end
  end
end
