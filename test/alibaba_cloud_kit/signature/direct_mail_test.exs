defmodule AlibabaCloudKit.Signature.DirectMailTest do
  use ExUnit.Case

  alias HTTPSpec.Request
  alias AlibabaCloudKit.Signature.DirectMail

  describe "sign/2" do
    setup do
      opts = [
        access_key_id: "testid",
        access_key_secret: "testsecret",
        at: ~U[2016-10-20 06:27:56Z]
      ]

      %{opts: opts}
    end

    test "works", %{opts: opts} do
      request =
        Request.new!(
          method: :post,
          scheme: :https,
          host: "dm.aliyuncs.com",
          port: 443,
          path: "/",
          headers: [{"content-type", "application/x-www-form-urlencoded"}],
          body:
            URI.encode_query(
              %{
                "Format" => "XML",
                "Version" => "2015-11-23",
                "Action" => "SingleSendMail",
                "AccountName" => "<a%b'>",
                "AddressType" => "1",
                "RegionId" => "cn-hangzhou",
                "HtmlBody" => "4",
                "ReplyToAddress" => "true",
                "Subject" => "3",
                "TagName" => "2",
                "ToAddress" => "1@test.com",
                # test only
                "SignatureNonce" => "c1b2c332-4cfb-4a0f-b8cc-ebe622aa0a5c"
              },
              :www_form
            )
        )

      request = DirectMail.sign(request, opts)

      assert %{
               "AccessKeyId" => "testid",
               "AccountName" => "<a%b'>",
               "Action" => "SingleSendMail",
               "AddressType" => "1",
               "Format" => "XML",
               "HtmlBody" => "4",
               "RegionId" => "cn-hangzhou",
               "ReplyToAddress" => "true",
               "Signature" => "llJfXJjBW3OacrVgxxsITgYaYm0=",
               "SignatureMethod" => "HMAC-SHA1",
               "SignatureNonce" => "c1b2c332-4cfb-4a0f-b8cc-ebe622aa0a5c",
               "SignatureVersion" => "1.0",
               "Subject" => "3",
               "TagName" => "2",
               "Timestamp" => "2016-10-20T06:27:56Z",
               "ToAddress" => "1@test.com",
               "Version" => "2015-11-23"
             } = URI.decode_query(request.body, %{}, :www_form)
    end
  end
end
