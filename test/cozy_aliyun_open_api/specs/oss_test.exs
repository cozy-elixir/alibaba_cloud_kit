defmodule CozyAliyunOpenAPI.Specs.OSSTest do
  use ExUnit.Case, async: false

  import Mox

  alias CozyAliyunOpenAPI.Config
  alias CozyAliyunOpenAPI.Specs.OSS
  alias CozyAliyunOpenAPI.HTTPRequest
  alias CozyAliyunOpenAPI.HTTPClient

  setup :verify_on_exit!

  @example_image_binary "../../files/lenna.png"
                        |> Path.expand(__DIR__)
                        |> File.read!()

  describe "Turning an OSS spec as an HTTP request" do
    setup do
      config =
        Config.new!(%{
          access_key_id: System.fetch_env!("OSS_ACCESS_KEY_ID"),
          access_key_secret: System.fetch_env!("OSS_ACCESS_KEY_SECRET")
        })

      region = System.fetch_env!("OSS_REGION")
      bucket = System.fetch_env!("OSS_BUCKET")

      %{config: config, region: region, bucket: bucket}
    end

    test "works for Service operations - take ListBuckets as example", %{
      config: config,
      region: region
    } do
      assert {:ok, 200, _header, _body} =
               OSS.new!(config, %{
                 region: region,
                 endpoint: "https://#{region}.aliyuncs.com/",
                 method: :get,
                 path: "/"
               })
               |> HTTPRequest.from_spec!()
               |> HTTPClient.request()
    end

    test "works for Region operations - take DescribeRegions as example", %{
      config: config,
      region: region
    } do
      assert {:ok, 200, _header, _body} =
               OSS.new!(config, %{
                 region: region,
                 endpoint: "https://#{region}.aliyuncs.com/",
                 method: :get,
                 path: "/",
                 query: %{"regions" => nil}
               })
               |> HTTPRequest.from_spec!()
               |> HTTPClient.request()
    end

    test "works for Bucket operations - take ListObjectsV2 as example", %{
      config: config,
      region: region,
      bucket: bucket
    } do
      assert {:ok, 200, _header, _body} =
               OSS.new!(config, %{
                 region: region,
                 bucket: bucket,
                 endpoint: "https://#{bucket}.#{region}.aliyuncs.com/",
                 method: :get,
                 path: "/",
                 query: %{"list-type" => 2}
               })
               |> HTTPRequest.from_spec!()
               |> HTTPClient.request()
    end

    test "works for Object operations - take PutObject as example", %{
      config: config,
      region: region,
      bucket: bucket
    } do
      assert {:ok, 200, _header, _body} =
               OSS.new!(config, %{
                 region: region,
                 bucket: bucket,
                 endpoint: "https://#{bucket}.#{region}.aliyuncs.com/",
                 method: :put,
                 path: "/oss/put_object.png",
                 body: @example_image_binary
               })
               |> HTTPRequest.from_spec!()
               |> HTTPClient.request()
    end

    test "works for LiveChannel operations - take ListLiveChannel as example", %{
      config: config,
      region: region,
      bucket: bucket
    } do
      assert {:ok, 200, _header, _body} =
               OSS.new!(config, %{
                 region: region,
                 bucket: bucket,
                 endpoint: "https://#{bucket}.#{region}.aliyuncs.com/",
                 method: :get,
                 path: "/",
                 query: %{"live" => nil}
               })
               |> HTTPRequest.from_spec!()
               |> HTTPClient.request()
    end
  end

  describe "Turning an OSS spec as an HTTP url" do
    setup do
      config =
        Config.new!(%{
          access_key_id: System.fetch_env!("OSS_ACCESS_KEY_ID"),
          access_key_secret: System.fetch_env!("OSS_ACCESS_KEY_SECRET")
        })

      region = System.fetch_env!("OSS_REGION")
      bucket = System.fetch_env!("OSS_BUCKET")

      %{config: config, region: region, bucket: bucket}
    end

    test "works for Object operations - take GetObject as example", %{
      config: config,
      region: region,
      bucket: bucket
    } do
      url =
        OSS.new!(config, %{
          sign_type: :url,
          region: region,
          bucket: bucket,
          endpoint: "https://#{bucket}.#{region}.aliyuncs.com/",
          method: :get,
          path: "/oss/get_object.png"
        })
        |> HTTPRequest.from_spec!()
        |> HTTPRequest.url()

      assert {:ok,
              %Finch.Response{
                status: 200
              }} = Finch.build(:get, url) |> Finch.request(CozyAliyunOpenAPI.Finch)
    end
  end

  # These tests using the data from official docs are for validating the
  # signing algorithm.
  describe "HTTPRequest.Transform" do
    setup do
      config =
        Config.new!(%{
          access_key_id: "accesskeyid",
          access_key_secret: "accesskeysecret"
        })

      %{config: config}
    end

    test "to_request!/1 works for spec whose sign_type is :header ", %{config: config} do
      spec =
        OSS.new!(config, %{
          sign_type: :header,
          region: "cn-hangzhou",
          bucket: "examplebucket",
          endpoint: "https://examplebucket.oss-cn-hangzhou.aliyuncs.com/",
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

      Application.put_env(:cozy_aliyun_open_api, :easy_time, CozyAliyunOpenAPI.EasyTimeMock)
      on_exit(fn -> Application.delete_env(:cozy_aliyun_open_api, :easy_time) end)

      CozyAliyunOpenAPI.EasyTimeMock
      |> expect(:utc_now, 1, fn :second -> ~U[2023-12-03 12:12:12Z] end)
      |> expect(:utc_today, 1, fn -> ~D[2023-12-03] end)
      |> expect(:to_rfc1123, 1, fn ~U[2023-12-03 12:12:12Z] -> "Sun, 03 Dec 2023 12:12:12 GMT" end)
      |> expect(:to_basic_iso8601, 1, fn ~U[2023-12-03 12:12:12Z] -> "20231203T121212Z" end)
      |> expect(:to_basic_iso8601, 1, fn ~D[2023-12-03] -> "20231203" end)

      assert %CozyAliyunOpenAPI.HTTPRequest{
               scheme: "https",
               host: "examplebucket.oss-cn-hangzhou.aliyuncs.com",
               port: 443,
               method: :put,
               path: "/exampleobject",
               query: %{},
               headers: %{
                 "authorization" =>
                   "OSS4-HMAC-SHA256 Credential=accesskeyid/20231203/cn-hangzhou/oss/aliyun_v4_request, AdditionalHeaders=host, Signature=4b663e424d2db9967401ff6ce1c86f8c83cabd77d9908475239d9110642c63fa",
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
             } = HTTPRequest.Transform.to_request!(spec)
    end

    test "to_request!/1 works for spec whose sign_type is :url ", %{config: config} do
      spec =
        OSS.new!(config, %{
          sign_type: :url,
          region: "cn-hangzhou",
          bucket: "examplebucket",
          endpoint: "https://examplebucket.oss-cn-hangzhou.aliyuncs.com/",
          method: :put,
          path: "/exampleobject",
          query: %{
            "x-oss-expires" => 86400
          },
          headers: %{
            "x-oss-meta-author" => "alice",
            "x-oss-meta-magic" => "abracadabra"
          }
        })

      Application.put_env(:cozy_aliyun_open_api, :easy_time, CozyAliyunOpenAPI.EasyTimeMock)
      on_exit(fn -> Application.delete_env(:cozy_aliyun_open_api, :easy_time) end)

      CozyAliyunOpenAPI.EasyTimeMock
      |> expect(:utc_now, 1, fn :second -> ~U[2023-12-03 12:12:12Z] end)
      |> expect(:utc_today, 1, fn -> ~D[2023-12-03] end)
      |> expect(:to_rfc1123, 1, fn ~U[2023-12-03 12:12:12Z] -> "Sun, 03 Dec 2023 12:12:12 GMT" end)
      |> expect(:to_basic_iso8601, 1, fn ~U[2023-12-03 12:12:12Z] -> "20231203T121212Z" end)
      |> expect(:to_basic_iso8601, 1, fn ~D[2023-12-03] -> "20231203" end)

      request = HTTPRequest.Transform.to_request!(spec)

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
                 "x-oss-expires" => 86400,
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
             } = request
    end

    test "to_url/1 works" do
      request = %CozyAliyunOpenAPI.HTTPRequest{
        scheme: "https",
        host: "examplebucket.oss-cn-hangzhou.aliyuncs.com",
        port: 443,
        method: :put,
        path: "/exampleobject",
        query: %{
          "x-oss-additional-headers" => "host",
          "x-oss-credential" => "accesskeyid/20231203/cn-hangzhou/oss/aliyun_v4_request",
          "x-oss-date" => "20231203T121212Z",
          "x-oss-expires" => 86400,
          "x-oss-signature" => "a0b8d0aee4e07c66637e6f8e839648970172cc7f9ef3e6be7a6f89083be2db4c",
          "x-oss-signature-version" => "OSS4-HMAC-SHA256"
        },
        headers: %{
          "date" => "Sun, 03 Dec 2023 12:12:12 GMT",
          "host" => "examplebucket.oss-cn-hangzhou.aliyuncs.com",
          "x-oss-meta-author" => "alice",
          "x-oss-meta-magic" => "abracadabra"
        },
        body: nil
      }

      assert "https://examplebucket.oss-cn-hangzhou.aliyuncs.com/exampleobject?x-oss-additional-headers=host&x-oss-credential=accesskeyid%2F20231203%2Fcn-hangzhou%2Foss%2Faliyun_v4_request&x-oss-date=20231203T121212Z&x-oss-expires=86400&x-oss-signature=a0b8d0aee4e07c66637e6f8e839648970172cc7f9ef3e6be7a6f89083be2db4c&x-oss-signature-version=OSS4-HMAC-SHA256" ==
               HTTPRequest.url(request)
    end
  end
end
