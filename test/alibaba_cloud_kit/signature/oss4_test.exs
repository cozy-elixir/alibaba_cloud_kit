defmodule AlibabaCloudKit.Signature.OSS4Test do
  use ExUnit.Case

  alias HTTPSpec.Request
  alias AlibabaCloudKit.Signature.OSS4

  describe "sign!/2" do
    setup do
      opts = [
        access_key_id: "access_key_id",
        access_key_secret: "access_key_secret",
        region: "oss-us-west-1",
        bucket: "example-bucket",
        at: ~U[2023-12-03 12:12:12Z]
      ]

      %{opts: opts}
    end

    test "with sign_type: :header", %{opts: opts} do
      opts = opts ++ [sign_type: :header]

      request =
        Request.new!(
          method: :put,
          scheme: :https,
          host: "example-bucket.oss-us-west-1.aliyuncs.com",
          port: 443,
          path: "/example-object",
          headers: [
            {"content-md5", "eB5eJF1ptWaXm4bijSPyxw"},
            {"content-type", "text/html"},
            {"x-oss-meta-author", "alice"},
            {"x-oss-meta-magic", "abracadabra"}
          ]
        )

      assert Request.new!(
               method: :put,
               scheme: :https,
               host: "example-bucket.oss-us-west-1.aliyuncs.com",
               port: 443,
               path: "/example-object",
               headers: [
                 {"content-md5", "eB5eJF1ptWaXm4bijSPyxw"},
                 {"content-type", "text/html"},
                 {"x-oss-meta-author", "alice"},
                 {"x-oss-meta-magic", "abracadabra"},
                 {"host", "example-bucket.oss-us-west-1.aliyuncs.com"},
                 {"date", "Sun, 03 Dec 2023 12:12:12 GMT"},
                 {"x-oss-date", "20231203T121212Z"},
                 {"x-oss-content-sha256", "UNSIGNED-PAYLOAD"},
                 {"authorization",
                  "OSS4-HMAC-SHA256 Credential=access_key_id/20231203/us-west-1/oss/aliyun_v4_request,AdditionalHeaders=host,Signature=5c2aa63aab5b9be722be76ecbffa5e93530961a37ab5b3b240167ad5c5eab8b3"}
               ]
             ) == OSS4.sign!(request, opts)
    end

    test "with sign_type: :query", %{opts: opts} do
      opts = opts ++ [sign_type: :query]

      request =
        Request.new!(
          method: :get,
          scheme: :https,
          host: "example-bucket.oss-us-west-1.aliyuncs.com",
          port: 443,
          path: "/example-object",
          query: "x-oss-expires=86400",
          headers: [
            {"x-oss-meta-author", "alice"},
            {"x-oss-meta-magic", "abracadabra"}
          ]
        )

      assert %HTTPSpec.Request{
               method: :get,
               scheme: :https,
               host: "example-bucket.oss-us-west-1.aliyuncs.com",
               port: 443,
               path: "/example-object",
               query: query,
               headers: [
                 {"x-oss-meta-author", "alice"},
                 {"x-oss-meta-magic", "abracadabra"},
                 {"host", "example-bucket.oss-us-west-1.aliyuncs.com"},
                 {"date", "Sun, 03 Dec 2023 12:12:12 GMT"}
               ]
             } =
               OSS4.sign!(request, opts)

      assert "x-oss-additional-headers=host&x-oss-credential=access_key_id%2F20231203%2Fus-west-1%2Foss%2Faliyun_v4_request&x-oss-date=20231203T121212Z&x-oss-expires=86400&x-oss-signature=249f96e9fc15147fcdfcd9f2686b6507ceabaa0c6eeb82b5a462dbc264a61030&x-oss-signature-version=OSS4-HMAC-SHA256" ==
               query

      assert %{
               "x-oss-additional-headers" => "host",
               "x-oss-credential" => "access_key_id/20231203/us-west-1/oss/aliyun_v4_request",
               "x-oss-date" => "20231203T121212Z",
               "x-oss-expires" => "86400",
               "x-oss-signature" =>
                 "249f96e9fc15147fcdfcd9f2686b6507ceabaa0c6eeb82b5a462dbc264a61030",
               "x-oss-signature-version" => "OSS4-HMAC-SHA256"
             } == URI.decode_query(query)
    end
  end

  describe "issues signed requests whose signature are added to header" do
    @describetag external: true

    @example_image_binary "../../files/lenna.png"
                          |> Path.expand(__DIR__)
                          |> File.read!()

    setup do
      %{
        access_key_id: System.fetch_env!("TEST_ACCESS_KEY_ID"),
        access_key_secret: System.fetch_env!("TEST_ACCESS_KEY_SECRET"),
        region: System.fetch_env!("TEST_OSS_REGION"),
        bucket: System.fetch_env!("TEST_OSS_BUCKET")
      }
    end

    test "works for Service operations - take ListBuckets as example", %{
      access_key_id: access_key_id,
      access_key_secret: access_key_secret,
      region: region
    } do
      request =
        HTTPSpec.Request.new!(
          method: :get,
          scheme: :https,
          host: "#{region}.aliyuncs.com",
          port: 443,
          path: "/"
        )

      opts = [
        access_key_id: access_key_id,
        access_key_secret: access_key_secret,
        region: region
      ]

      assert {:ok, %{status: 200}} =
               request
               |> OSS4.sign!(opts)
               |> HTTPClient.send_request()
    end

    test "works for Region operations - take DescribeRegions as example", %{
      access_key_id: access_key_id,
      access_key_secret: access_key_secret,
      region: region
    } do
      request =
        HTTPSpec.Request.new!(
          method: :get,
          scheme: :https,
          host: "#{region}.aliyuncs.com",
          port: 443,
          path: "/",
          query: "regions"
        )

      opts = [
        access_key_id: access_key_id,
        access_key_secret: access_key_secret,
        region: region
      ]

      assert {:ok, %{status: 200}} =
               request
               |> OSS4.sign!(opts)
               |> HTTPClient.send_request()
    end

    test "works for Bucket operations - take ListObjectsV2 as example", %{
      access_key_id: access_key_id,
      access_key_secret: access_key_secret,
      region: region,
      bucket: bucket
    } do
      request =
        HTTPSpec.Request.new!(
          method: :get,
          scheme: :https,
          host: "#{bucket}.#{region}.aliyuncs.com",
          port: 443,
          path: "/",
          query: "list-type=2"
        )

      opts = [
        access_key_id: access_key_id,
        access_key_secret: access_key_secret,
        region: region,
        bucket: bucket
      ]

      assert {:ok, %{status: 200}} =
               request
               |> OSS4.sign!(opts)
               |> HTTPClient.send_request()
    end

    test "works for Object operations - take PutObject as example", %{
      access_key_id: access_key_id,
      access_key_secret: access_key_secret,
      region: region,
      bucket: bucket
    } do
      request =
        HTTPSpec.Request.new!(
          method: :put,
          scheme: :https,
          host: "#{bucket}.#{region}.aliyuncs.com",
          port: 443,
          path: "/oss/put_object.png",
          body: @example_image_binary
        )

      opts = [
        access_key_id: access_key_id,
        access_key_secret: access_key_secret,
        region: region,
        bucket: bucket
      ]

      assert {:ok, %{status: 200}} =
               request
               |> OSS4.sign!(opts)
               |> HTTPClient.send_request()
    end

    test "works for LiveChannel operations - take ListLiveChannel as example", %{
      access_key_id: access_key_id,
      access_key_secret: access_key_secret,
      region: region,
      bucket: bucket
    } do
      request =
        HTTPSpec.Request.new!(
          method: :get,
          scheme: :https,
          host: "#{bucket}.#{region}.aliyuncs.com",
          port: 443,
          path: "/",
          query: "live"
        )

      opts = [
        access_key_id: access_key_id,
        access_key_secret: access_key_secret,
        region: region,
        bucket: bucket
      ]

      assert {:ok, %{status: 200}} =
               request
               |> OSS4.sign!(opts)
               |> HTTPClient.send_request()
    end
  end

  describe "issues signed requests whose signature are added to query" do
    @describetag external: true

    setup do
      %{
        access_key_id: System.fetch_env!("TEST_ACCESS_KEY_ID"),
        access_key_secret: System.fetch_env!("TEST_ACCESS_KEY_SECRET"),
        region: System.fetch_env!("TEST_OSS_REGION"),
        bucket: System.fetch_env!("TEST_OSS_BUCKET")
      }
    end

    test "works for Object operations - take GetObject as example", %{
      access_key_id: access_key_id,
      access_key_secret: access_key_secret,
      region: region,
      bucket: bucket
    } do
      request =
        HTTPSpec.Request.new!(
          method: :get,
          scheme: :https,
          host: "#{bucket}.#{region}.aliyuncs.com",
          port: 443,
          path: "/oss/get_object.png"
        )

      opts = [
        access_key_id: access_key_id,
        access_key_secret: access_key_secret,
        region: region,
        bucket: bucket,
        sign_type: :query
      ]

      assert {:ok, %{status: 200}} =
               request
               |> OSS4.sign!(opts)
               |> Request.build_url()
               |> HTTPClient.send_request()
    end
  end
end
