defmodule CozyAliyunOpenAPI.Sign.ACS3Test do
  use ExUnit.Case

  alias CozyAliyunOpenAPI.Config
  alias CozyAliyunOpenAPI.HTTP.Request
  alias CozyAliyunOpenAPI.Sign.ACS3

  test "sign/2" do
    config =
      Config.new!(
        access_key_id: "YourAccessKeyId",
        access_key_secret: "YourAccessKeySecret"
      )

    request =
      Request.new!(%{
        scheme: "https",
        host: "ecs.cn-shanghai.aliyuncs.com",
        port: 443,
        method: :post,
        path: "/",
        query: %{
          "ImageId" => "win2019_1809_x64_dtc_zh-cn_40G_alibase_20230811.vhd",
          "RegionId" => "cn-shanghai"
        },
        headers: %{
          "x-acs-version" => "2014-05-26",
          "x-acs-action" => "RunInstances",
          "x-acs-signature-nonce" => "3156853299f313e23d1673dc12e1703d"
        }
      })

    assert %Request{
             scheme: "https",
             host: "ecs.cn-shanghai.aliyuncs.com",
             port: 443,
             method: :post,
             path: "/",
             query: %{
               "ImageId" => "win2019_1809_x64_dtc_zh-cn_40G_alibase_20230811.vhd",
               "RegionId" => "cn-shanghai"
             },
             headers: %{
               "authorization" =>
                 "ACS3-HMAC-SHA256 Credential=YourAccessKeyId,SignedHeaders=host;x-acs-action;x-acs-content-sha256;x-acs-date;x-acs-signature-nonce;x-acs-version,Signature=06563a9e1b43f5dfe96b81484da74bceab24a1d853912eee15083a6f0f3283c0",
               "host" => "ecs.cn-shanghai.aliyuncs.com",
               "x-acs-action" => "RunInstances",
               "x-acs-content-sha256" =>
                 "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
               "x-acs-date" => "2023-10-26T10:22:32Z",
               "x-acs-signature-nonce" => "3156853299f313e23d1673dc12e1703d",
               "x-acs-version" => "2014-05-26"
             },
             body: nil
           } = ACS3.sign(request, at: ~U[2023-10-26 10:22:32Z], config: config)
  end
end
