defmodule CozyAliyunOpenAPI.Specs.OSS.ObjectTest do
  use ExUnit.Case

  alias CozyAliyunOpenAPI.Config
  alias CozyAliyunOpenAPI.Specs.OSS.Object

  @example_image_binary "../../../files/lenna.png"
                        |> Path.expand(__DIR__)
                        |> File.read!()

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

  test "presign_post_object/5", %{
    config: config,
    region: region,
    bucket: bucket
  } do
    url = "https://#{bucket}.#{region}.aliyuncs.com"

    key = "object/presign_post_object.png"
    acl = "private"
    max_size_in_bytes = 1024 * 1024 * 100

    conditions = [
      ["eq", "$key", key],
      ["eq", "$x-oss-object-acl", acl],
      ["content-length-range", 1, max_size_in_bytes]
    ]

    seconds_to_expire = 3600

    %{
      policy: policy,
      "x-oss-credential": x_oss_credential,
      "x-oss-date": x_oss_date,
      "x-oss-signature-version": x_oss_signature_version,
      "x-oss-signature": x_oss_signature
    } = Object.presign_post_object(config, region, bucket, conditions, seconds_to_expire)

    alias Tesla.Multipart

    mp =
      Multipart.new()
      |> Multipart.add_field("key", key)
      |> Multipart.add_field("x-oss-object-acl", acl)
      |> Multipart.add_field("policy", policy)
      |> Multipart.add_field("x-oss-credential", x_oss_credential)
      |> Multipart.add_field("x-oss-date", x_oss_date)
      |> Multipart.add_field("x-oss-signature-version", x_oss_signature_version)
      |> Multipart.add_field("x-oss-signature", x_oss_signature)
      |> Multipart.add_file_content(@example_image_binary, "lenna.png")

    assert {:ok, %{status: 204}} = Tesla.post(url, mp)
  end
end
