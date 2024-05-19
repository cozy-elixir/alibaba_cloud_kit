defmodule CozyAliyunOpenAPI.Specs.OSS.Object do
  @moduledoc """
  Provides object related utils.
  """

  alias CozyAliyunOpenAPI.Config
  alias CozyAliyunOpenAPI.EasyTime
  alias CozyAliyunOpenAPI.Sign.OSS4
  alias CozyAliyunOpenAPI.Specs.OSS.Object.PostPolicy

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

      config =
        Config.new!(%{
          access_key_id: "...",
          access_key_secret: "..."
        })

      region = "oss-us-west-1"
      bucket = "example-bucket"
      conditions = [
        ["eq", "$key", "lenna.png"],
        ["eq", "$x-oss-object-acl", "private"],
        ["content-length-range", 1, 1024 * 1024 * 5]
      ]
      seconds_to_expire = 3600

      presign_post_object(config, region, bucket, conditions, seconds_to_expire)

      # returns:
      #
      # %{
      #   policy: "eyJjb25ka ... jM1OjUxWiJ9",
      #   "x-oss-signature-version": "OSS4-HMAC-SHA256",
      #   "x-oss-credential": ".../20240519/us-west-1/oss/aliyun_v4_request",
      #   "x-oss-date": "20240519T143551Z",
      #   "x-oss-signature": "4526fe7c1e9f58f3da7edbfb31758721564f38bfba5cdd3f5d8d5ae67a60c60b"
      # }

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
    now = EasyTime.utc_now(:second)

    %{
      signature_version: signature_version,
      credential: credential,
      datetime: datetime
    } =
      OSS4.prepare_sign_info_for_post_policy(
        at: now,
        config: config,
        region: region,
        bucket: bucket
      )

    post_policy = %PostPolicy{
      expiration: build_expiration(now, seconds_to_expire),
      conditions: [
        %{bucket: bucket},
        %{"x-oss-signature-version": signature_version},
        %{"x-oss-credential": credential},
        %{"x-oss-date": datetime}
        | conditions
      ]
    }

    %{post_policy: post_policy, signature: signature} =
      OSS4.sign(post_policy, at: now, config: config, region: region, bucket: bucket)

    %{
      policy: post_policy,
      "x-oss-signature-version": signature_version,
      "x-oss-credential": credential,
      "x-oss-date": datetime,
      "x-oss-signature": signature
    }
  end

  defp build_expiration(%DateTime{} = start, seconds_to_expire) do
    start
    |> DateTime.add(seconds_to_expire, :second)
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601()
  end
end
