defmodule AlibabaCloudKit.Signature.ACS3Test do
  use ExUnit.Case

  alias AlibabaCloudKit.Signature.ACS3
  alias HTTPSpec.Request

  describe "sign!/2" do
    setup do
      opts = [
        access_key_id: "access_key_id",
        access_key_secret: "access_key_secret",
        at: ~U[2024-07-13 14:40:50Z]
      ]

      %{opts: opts}
    end

    test "works for GET request", %{opts: opts} do
      assert Request.new!(
               scheme: :https,
               host: "ecs.us-west-1.aliyuncs.com",
               port: 443,
               method: :get,
               path: "/",
               query: "RegionId=us-west-1",
               headers: [
                 {"x-acs-version", "2014-05-26"},
                 {"x-acs-action", "DescribeInstanceStatus"},
                 {"x-acs-signature-nonce", "6cdc1971b2470b4c83b78a35e2bc36ea"},
                 {"host", "ecs.us-west-1.aliyuncs.com"},
                 {"x-acs-date", "2024-07-13T14:40:50Z"},
                 {"x-acs-content-sha256",
                  "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"},
                 {"authorization",
                  "ACS3-HMAC-SHA256 Credential=access_key_id,SignedHeaders=host;x-acs-action;x-acs-content-sha256;x-acs-date;x-acs-signature-nonce;x-acs-version,Signature=cd60b476dd38f9c2714f54e604662aff3b033e5d05ac80ea35b4c7c1eb76bfb0"}
               ],
               body: nil
             ) ==
               Request.new!(
                 method: :get,
                 scheme: :https,
                 host: "ecs.us-west-1.aliyuncs.com",
                 port: 443,
                 path: "/",
                 query: URI.encode_query(%{"RegionId" => "us-west-1"}, :www_form),
                 headers: [
                   {"x-acs-version", "2014-05-26"},
                   {"x-acs-action", "DescribeInstanceStatus"},
                   # for test only
                   {"x-acs-signature-nonce", "6cdc1971b2470b4c83b78a35e2bc36ea"}
                 ]
               )
               |> ACS3.sign!(opts)
    end

    test "works for POST request", %{opts: opts} do
      assert Request.new!(
               scheme: :https,
               host: "ecs.us-west-1.aliyuncs.com",
               port: 443,
               method: :post,
               path: "/",
               query: nil,
               headers: [
                 {"content-type", "application/x-www-form-urlencoded"},
                 {"x-acs-version", "2014-05-26"},
                 {"x-acs-action", "DescribeInstanceStatus"},
                 {"x-acs-signature-nonce", "fdcec2963e364bad483f79877d6cd101"},
                 {"host", "ecs.us-west-1.aliyuncs.com"},
                 {"x-acs-date", "2024-07-13T14:40:50Z"},
                 {"x-acs-content-sha256",
                  "4467215d6f96bece91b2019ec59bb2ff38432705ca1ddc908d0daab4a63deaa0"},
                 {"authorization",
                  "ACS3-HMAC-SHA256 Credential=access_key_id,SignedHeaders=content-type;host;x-acs-action;x-acs-content-sha256;x-acs-date;x-acs-signature-nonce;x-acs-version,Signature=a72e21b7e8a4ae09f3cf5162a132ca14220f8ae32decc8c5b6109fca77a51006"}
               ],
               body: "RegionId=us-west-1"
             ) ==
               Request.new!(
                 method: :post,
                 scheme: :https,
                 host: "ecs.us-west-1.aliyuncs.com",
                 port: 443,
                 path: "/",
                 headers: [
                   {"content-type", "application/x-www-form-urlencoded"},
                   {"x-acs-version", "2014-05-26"},
                   {"x-acs-action", "DescribeInstanceStatus"},
                   # for test only
                   {"x-acs-signature-nonce", "fdcec2963e364bad483f79877d6cd101"}
                 ],
                 body: URI.encode_query(%{"RegionId" => "us-west-1"}, :www_form)
               )
               |> ACS3.sign!(opts)
    end
  end

  describe "issues signed request" do
    @describetag external: true

    setup do
      opts = [
        access_key_id: System.fetch_env!("TEST_ACCESS_KEY_ID"),
        access_key_secret: System.fetch_env!("TEST_ACCESS_KEY_SECRET")
      ]

      %{opts: opts}
    end

    test "GET", %{opts: opts} do
      assert {:ok, %{status: 200}} =
               Request.new!(
                 method: :get,
                 scheme: :https,
                 host: "ecs.us-west-1.aliyuncs.com",
                 port: 443,
                 path: "/",
                 query: URI.encode_query(%{"RegionId" => "us-west-1"}, :www_form),
                 headers: [
                   {"x-acs-version", "2014-05-26"},
                   {"x-acs-action", "DescribeInstanceStatus"}
                 ]
               )
               |> ACS3.sign!(opts)
               |> HTTPClient.send_request()
    end

    test "POST", %{opts: opts} do
      assert {:ok, %{status: 200}} =
               Request.new!(
                 method: :post,
                 scheme: :https,
                 host: "ecs.us-west-1.aliyuncs.com",
                 port: 443,
                 path: "/",
                 headers: [
                   {"content-type", "application/x-www-form-urlencoded"},
                   {"x-acs-version", "2014-05-26"},
                   {"x-acs-action", "DescribeInstanceStatus"}
                 ],
                 body: URI.encode_query(%{"RegionId" => "us-west-1"}, :www_form)
               )
               |> ACS3.sign!(opts)
               |> HTTPClient.send_request()
    end
  end
end
