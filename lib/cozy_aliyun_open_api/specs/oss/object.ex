defmodule CozyAliyunOpenAPI.Specs.OSS.Object do
  @moduledoc """
  Provides object related utils.
  """

  import CozyAliyunOpenAPI.Utils,
    only: [
      encode_json!: 1,
      hmac_sha256: 2,
      base16: 1,
      base64: 1
    ]

  alias CozyAliyunOpenAPI.Config
  alias CozyAliyunOpenAPI.EasyTime

  @doc """
  Presigns a `PostObject` operation and returns the necessary form data when
  executing the `PostObject` operation.

  Read more at:

    * [PostObject](https://www.alibabacloud.com/help/en/oss/developer-reference/postobject)
    * [PostObject (zh-Hans)](https://help.aliyun.com/zh/oss/developer-reference/postobject)

  ## Adding signature

  This implementation has built-in V4 signature support.

  > V1 signature is not supported.

  ## Examples

      region = "oss-us-west-1"
      bucket = "example-bucket"
      conditions = [
        ["eq", "$key", "lenna.png"],
        ["eq", "$x-oss-object-acl", "private"],
        ["content-length-range", 1, 1024 * 1024 * 5]
      ]
      seconds_to_expire = 3600

      sign_post_object_policy(config, region, bucket, conditions, seconds_to_expire)

  """

  @spec presign_post_object(Config.t(), String.t(), String.t(), list(), pos_integer()) :: %{
          policy: String.t(),
          "x-oss-signature-version": String.t(),
          "x-oss-credential": String.t(),
          "x-oss-date": String.t(),
          "x-oss-signature": String.t()
        }
  def presign_post_object(%Config{} = config, region, bucket, conditions, seconds_to_expire)
      when is_list(conditions) and is_integer(seconds_to_expire) do
    signature_version = "OSS4-HMAC-SHA256"
    utc_datetime = EasyTime.utc_now(:second)
    utc_datetime_in_iso8601 = EasyTime.to_basic_iso8601(utc_datetime)
    utc_date_in_iso8601 = EasyTime.utc_today() |> EasyTime.to_basic_iso8601()

    sign_args = %{
      signature_version: signature_version,
      access_key_version: "aliyun_v4",
      request_version: "aliyun_v4_request",
      service: "oss",
      datetime: utc_datetime_in_iso8601,
      date: utc_date_in_iso8601,
      config: config,
      region: String.trim_leading(region, "oss-")
    }

    x_oss_signature_version = signature_version
    x_oss_credential = build_credential(sign_args)
    x_oss_date = utc_datetime_in_iso8601

    raw_policy = %{
      expiration: build_expiration(utc_datetime, seconds_to_expire),
      conditions: [
        %{bucket: bucket},
        %{"x-oss-signature-version": x_oss_signature_version},
        %{"x-oss-credential": x_oss_credential},
        %{"x-oss-date": x_oss_date}
        | conditions
      ]
    }

    policy =
      raw_policy
      |> encode_json!()
      |> base64()

    %{
      policy: policy,
      "x-oss-signature-version": x_oss_signature_version,
      "x-oss-credential": x_oss_credential,
      "x-oss-date": x_oss_date,
      "x-oss-signature": sign({policy, sign_args})
    }
  end

  defp sign({policy, sign_args}) do
    %{
      config: %{access_key_secret: access_key_secret},
      access_key_version: access_key_version,
      request_version: request_version,
      service: service,
      region: region,
      date: date
    } = sign_args

    "#{access_key_version}#{access_key_secret}"
    |> hmac_sha256(date)
    |> hmac_sha256(region)
    |> hmac_sha256(service)
    |> hmac_sha256(request_version)
    |> hmac_sha256(policy)
    |> base16()
  end

  defp build_credential(sign_args) do
    %{
      config: %{access_key_id: access_key_id},
      request_version: request_version,
      service: service,
      region: region,
      date: date
    } = sign_args

    Enum.join([access_key_id, date, region, service, request_version], "/")
  end

  defp build_expiration(%DateTime{} = start, seconds_to_expire) do
    start
    |> DateTime.add(seconds_to_expire, :second)
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end
end
