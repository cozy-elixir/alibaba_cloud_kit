defmodule CozyAliyunOpenAPI.HTTPRequest.Sign.OSS4Test do
  use ExUnit.Case

  alias CozyAliyunOpenAPI.Config
  alias CozyAliyunOpenAPI.HTTPRequest
  alias CozyAliyunOpenAPI.HTTPRequest.Sign.OSS4

  setup do
    config =
      Config.new!(%{
        access_key_id: "accesskeyid",
        access_key_secret: "accesskeysecret"
      })

    %{config: config}
  end

  test "sign/2 with :header type", %{config: config} do
    request =
      HTTPRequest.new!(%{
        scheme: "https",
        host: "examplebucket.oss-cn-hangzhou.aliyuncs.com",
        port: 443,
        method: :put,
        path: "/exampleobject",
        query: %{},
        headers: %{
          "Content-MD5" => "eB5eJF1ptWaXm4bijSPyxw",
          "Content-Type" => "text/html",
          "x-oss-meta-author" => "alice",
          "x-oss-meta-magic" => "abracadabra"
        },
        body: nil
      })

    assert %CozyAliyunOpenAPI.HTTPRequest{
             scheme: "https",
             host: "examplebucket.oss-cn-hangzhou.aliyuncs.com",
             port: 443,
             method: :put,
             path: "/exampleobject",
             query: %{},
             headers: %{
               "authorization" =>
                 "OSS4-HMAC-SHA256 Credential=accesskeyid/20231203/cn-hangzhou/oss/aliyun_v4_request,AdditionalHeaders=host,Signature=4b663e424d2db9967401ff6ce1c86f8c83cabd77d9908475239d9110642c63fa",
               "content-md5" => "eB5eJF1ptWaXm4bijSPyxw",
               "content-type" => "text/html",
               "date" => "Sun, 03 Dec 2023 12:12:12 GMT",
               "host" => "examplebucket.oss-cn-hangzhou.aliyuncs.com",
               "x-oss-content-sha256" => "UNSIGNED-PAYLOAD",
               "x-oss-date" => "20231203T121212Z",
               "x-oss-meta-author" => "alice",
               "x-oss-meta-magic" => "abracadabra"
             },
             body: nil
           } =
             OSS4.sign(request,
               type: :header,
               at: ~U[2023-12-03 12:12:12Z],
               config: config,
               region: "oss-cn-hangzhou",
               bucket: "examplebucket"
             )
  end

  test "sign/2 with :url type", %{config: config} do
    request =
      HTTPRequest.new!(%{
        scheme: "https",
        host: "examplebucket.oss-cn-hangzhou.aliyuncs.com",
        port: 443,
        method: :put,
        path: "/exampleobject",
        query: %{
          "x-oss-expires" => 86_400
        },
        headers: %{
          "x-oss-meta-author" => "alice",
          "x-oss-meta-magic" => "abracadabra"
        },
        body: nil
      })

    assert %CozyAliyunOpenAPI.HTTPRequest{
             scheme: "https",
             host: "examplebucket.oss-cn-hangzhou.aliyuncs.com",
             port: 443,
             method: :put,
             path: "/exampleobject",
             query: %{
               "x-oss-additional-headers" => "host",
               "x-oss-credential" => "accesskeyid/20231203/cn-hangzhou/oss/aliyun_v4_request",
               "x-oss-date" => "20231203T121212Z",
               "x-oss-expires" => 86_400,
               "x-oss-signature" =>
                 "2c6c9f10d8950fb150290ef6f42570e33cd45d6a57ec7887de75fa2ec45b4c72",
               "x-oss-signature-version" => "OSS4-HMAC-SHA256"
             },
             headers: %{
               "date" => "Sun, 03 Dec 2023 12:12:12 GMT",
               "host" => "examplebucket.oss-cn-hangzhou.aliyuncs.com",
               "x-oss-meta-author" => "alice",
               "x-oss-meta-magic" => "abracadabra"
             },
             body: nil
           } =
             OSS4.sign(request,
               type: :url,
               at: ~U[2023-12-03 12:12:12Z],
               config: config,
               region: "oss-cn-hangzhou",
               bucket: "examplebucket"
             )
  end
end
