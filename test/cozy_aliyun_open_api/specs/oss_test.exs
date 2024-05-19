defmodule CozyAliyunOpenAPI.Specs.OSSTest do
  use ExUnit.Case

  alias CozyAliyunOpenAPI.Config
  alias CozyAliyunOpenAPI.Specs.OSS
  alias CozyAliyunOpenAPI.HTTPRequest
  alias CozyAliyunOpenAPI.HTTPClient

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
end
