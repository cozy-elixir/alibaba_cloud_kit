defmodule AlibabaCloudKit.Signature.DirectMailTest do
  use ExUnit.Case

  alias HTTPSpec.Request
  alias AlibabaCloudKit.Signature.DirectMail

  describe "sign!/2" do
    setup do
      opts = [
        access_key_id: "testid",
        access_key_secret: "testsecret",
        at: ~U[2016-10-20 06:27:56Z]
      ]

      %{opts: opts}
    end

    test "works for GET request", %{opts: opts} do
      request =
        Request.new!(
          method: :get,
          scheme: :https,
          host: "dm.aliyuncs.com",
          port: 443,
          path: "/",
          query:
            URI.encode_query(
              %{
                "Format" => "JSON",
                "Version" => "2015-11-23",
                "Action" => "SingleSendMail",
                "AccountName" => "admin@alibabacloudkit.zekedou.live",
                "AddressType" => "1",
                "ReplyToAddress" => "false",
                "FromAlias" => "AlibabaCloudKit Group",
                "Subject" => "Announcement of AlibabaCloudKit",
                "ToAddress" => "c4710n@pm.me",
                "TextBody" => "This is the test email send by GET test of AlibabaCloudKit.",
                # test only
                "SignatureNonce" => "c1b2c332-4cfb-4a0f-b8cc-ebe622aa0a5c"
              },
              :rfc3986
            )
        )

      request = DirectMail.sign!(request, opts)

      assert %{
               "AccessKeyId" => "testid",
               "AccountName" => "admin@alibabacloudkit.zekedou.live",
               "Action" => "SingleSendMail",
               "AddressType" => "1",
               "Format" => "JSON",
               "FromAlias" => "AlibabaCloudKit Group",
               "ReplyToAddress" => "false",
               "Signature" => "3DQvovq2PqyPBIHWjNEpNbh0BIo=",
               "SignatureMethod" => "HMAC-SHA1",
               "SignatureNonce" => "c1b2c332-4cfb-4a0f-b8cc-ebe622aa0a5c",
               "SignatureVersion" => "1.0",
               "Subject" => "Announcement of AlibabaCloudKit",
               "TextBody" => "This is the test email send by GET test of AlibabaCloudKit.",
               "Timestamp" => "2016-10-20T06:27:56Z",
               "ToAddress" => "c4710n@pm.me",
               "Version" => "2015-11-23"
             } == URI.decode_query(request.query, %{}, :rfc3986)
    end

    test "works for POST request", %{opts: opts} do
      request =
        Request.new!(
          method: :post,
          scheme: :https,
          host: "dm.aliyuncs.com",
          port: 443,
          path: "/",
          headers: [
            {"content-type", "application/x-www-form-urlencoded"}
          ],
          body:
            URI.encode_query(
              %{
                "Format" => "JSON",
                "Version" => "2015-11-23",
                "Action" => "SingleSendMail",
                "AccountName" => "admin@alibabacloudkit.zekedou.live",
                "AddressType" => "1",
                "ReplyToAddress" => "false",
                "FromAlias" => "AlibabaCloudKit Group",
                "Subject" => "Announcement of AlibabaCloudKit",
                "ToAddress" => "c4710n@pm.me",
                "TextBody" => "This is the test email send by POST test of AlibabaCloudKit.",
                # test only
                "SignatureNonce" => "c1b2c332-4cfb-4a0f-b8cc-ebe622aa0a5c"
              },
              :www_form
            )
        )

      request = DirectMail.sign!(request, opts)

      assert %{
               "AccessKeyId" => "testid",
               "AccountName" => "admin@alibabacloudkit.zekedou.live",
               "Action" => "SingleSendMail",
               "AddressType" => "1",
               "Format" => "JSON",
               "FromAlias" => "AlibabaCloudKit Group",
               "ReplyToAddress" => "false",
               "Signature" => "jh3q6OVvSs+6Q81upm9cyZkaRpU=",
               "SignatureMethod" => "HMAC-SHA1",
               "SignatureNonce" => "c1b2c332-4cfb-4a0f-b8cc-ebe622aa0a5c",
               "SignatureVersion" => "1.0",
               "Subject" => "Announcement of AlibabaCloudKit",
               "TextBody" => "This is the test email send by POST test of AlibabaCloudKit.",
               "Timestamp" => "2016-10-20T06:27:56Z",
               "ToAddress" => "c4710n@pm.me",
               "Version" => "2015-11-23"
             } == URI.decode_query(request.body, %{}, :www_form)
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
      request =
        Request.new!(
          method: :get,
          scheme: :https,
          host: "dm.aliyuncs.com",
          port: 443,
          path: "/",
          query:
            URI.encode_query(
              %{
                "Format" => "JSON",
                "Version" => "2015-11-23",
                "Action" => "SingleSendMail",
                "AccountName" => "admin@alibabacloudkit.zekedou.live",
                "AddressType" => "1",
                "ReplyToAddress" => "false",
                "FromAlias" => "AlibabaCloudKit Group",
                "Subject" => "Announcement of AlibabaCloudKit",
                "ToAddress" => "c4710n@pm.me",
                "TextBody" =>
                  "This is the test email send by GET test of AlibabaCloudKit.\n#{DateTime.utc_now() |> DateTime.to_iso8601(:extended)}"
              },
              :rfc3986
            )
        )

      assert {:ok, %{status: 200}} =
               request
               |> DirectMail.sign!(opts)
               |> HTTPClient.send_request()
    end

    test "POST", %{opts: opts} do
      request =
        Request.new!(
          method: :post,
          scheme: :https,
          host: "dm.aliyuncs.com",
          port: 443,
          path: "/",
          headers: [
            {"content-type", "application/x-www-form-urlencoded"}
          ],
          body:
            URI.encode_query(
              %{
                "Format" => "JSON",
                "Version" => "2015-11-23",
                "Action" => "SingleSendMail",
                "AccountName" => "admin@alibabacloudkit.zekedou.live",
                "AddressType" => "1",
                "ReplyToAddress" => "false",
                "FromAlias" => "AlibabaCloudKit Group",
                "Subject" => "Announcement of AlibabaCloudKit",
                "ToAddress" => "c4710n@pm.me",
                "TextBody" =>
                  "This is the test email send by POST test of AlibabaCloudKit.\n#{DateTime.utc_now() |> DateTime.to_iso8601(:extended)}"
              },
              :www_form
            )
        )

      assert {:ok, %{status: 200}} =
               request
               |> DirectMail.sign!(opts)
               |> HTTPClient.send_request()
    end
  end
end
