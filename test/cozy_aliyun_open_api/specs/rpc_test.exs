defmodule CozyAliyunOpenAPI.Specs.RPCTest do
  use ExUnit.Case
  alias CozyAliyunOpenAPI.Config
  alias CozyAliyunOpenAPI.Specs.RPC

  setup do
    config =
      Config.new!(%{
        access_key_id: "testid",
        access_key_secret: "testsecret"
      })

    [config: config]
  end

  describe "new!/2" do
    test "creates a spec with valid signature", %{config: config} do
      rpc =
        RPC.new!(config, %{
          method: :post,
          protocol: :https,
          endpoint: "...",
          shared_params: %{
            "Action" => "SingleSendMail",
            "Version" => "2015-11-23",
            "Format" => "XML",
            "SignatureNonce" => "c1b2c332-4cfb-4a0f-b8cc-ebe622aa0a5c",
            "Timestamp" => "2016-10-20T06:27:56Z"
          },
          params: %{
            "AccountName" => "<a%b'>",
            "AddressType" => "1",
            "RegionId" => "cn-hangzhou",
            "HtmlBody" => "4",
            "ReplyToAddress" => "true",
            "Subject" => "3",
            "TagName" => "2",
            "ToAddress" => "1@test.com"
          }
        })

      expected_signature = "llJfXJjBW3OacrVgxxsITgYaYm0="
      assert rpc.shared_params["Signature"] == expected_signature
    end

    test "raises when method is invalid", %{config: config} do
      assert_raise ArgumentError, "key :method should be one of [:get, :post]", fn ->
        RPC.new!(config, %{})
      end

      assert_raise ArgumentError, "key :method should be one of [:get, :post]", fn ->
        RPC.new!(config, %{method: :bad_method})
      end
    end

    test "raises when protocol is invalid", %{config: config} do
      assert_raise ArgumentError, "key :protocol should be one of [:http, :https]", fn ->
        RPC.new!(config, %{method: :get})
      end

      assert_raise ArgumentError, "key :protocol should be one of [:http, :https]", fn ->
        RPC.new!(config, %{method: :get, protocol: :bad_protocol})
      end
    end

    test "raises when endpoint is invalid", %{config: config} do
      assert_raise ArgumentError, "key :endpoint should be provided", fn ->
        RPC.new!(config, %{method: :get, protocol: :https})
      end
    end
  end
end
