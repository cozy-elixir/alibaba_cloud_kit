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

  @example_spec_config %{
    method: :post,
    endpoint: "https://example.com",
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
  }

  @example_spec_config_signature "llJfXJjBW3OacrVgxxsITgYaYm0="

  describe "new!/2" do
    test "creates a spec with valid signature", %{config: config} do
      rpc = RPC.new!(config, @example_spec_config)
      assert rpc.shared_params["Signature"] == @example_spec_config_signature
    end

    test "raises when method is invalid", %{config: config} do
      assert_raise ArgumentError, "key :method should be one of [:get, :post]", fn ->
        RPC.new!(config, %{})
      end

      assert_raise ArgumentError, "key :method should be one of [:get, :post]", fn ->
        RPC.new!(config, %{method: :bad_method})
      end
    end

    test "raises when endpoint is invalid", %{config: config} do
      assert_raise ArgumentError, "key :endpoint should be provided", fn ->
        RPC.new!(config, %{method: :get, protocol: :https})
      end
    end
  end

  alias CozyAliyunOpenAPI.HTTPRequest

  describe "CozyAliyunOpenAPI.Specs.RPC" do
    test "implements protocol - CozyAliyunOpenAPI.HTTPRequest.Transform", %{config: config} do
      rpc = RPC.new!(config, @example_spec_config)
      assert %HTTPRequest{} = HTTPRequest.Transform.to_request!(rpc)
    end
  end
end
