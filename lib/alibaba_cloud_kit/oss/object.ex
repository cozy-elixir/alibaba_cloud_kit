defmodule AlibabaCloudKit.OSS.Object do
  @moduledoc """
  Provides object related helpers.
  """

  alias AlibabaCloudKit.Signature
  alias AlibabaCloudKit.OSS.Object.PostPolicy

  @type access_key_id :: String.t()
  @type access_key_secret :: String.t()
  @type region :: String.t()
  @type bucket :: String.t() | nil
  @type at :: DateTime.t() | nil

  @type sign_opt ::
          {:access_key_id, access_key_id()}
          | {:access_key_secret, access_key_secret()}
          | {:region, region()}
          | {:bucket, bucket()}
          | {:at, at()}
  @type sign_opts :: [sign_opt()]

  @sign_opts_definition NimbleOptions.new!(
                          access_key_id: [
                            type: :string,
                            required: true
                          ],
                          access_key_secret: [
                            type: :string,
                            required: true
                          ],
                          region: [
                            type: :string,
                            required: true
                          ],
                          bucket: [
                            type: {:or, [:string, nil]},
                            default: nil
                          ],
                          at: [
                            type: {:or, [{:struct, DateTime}, nil]},
                            default: nil
                          ]
                        )

  @doc ~S"""
  Presigns a `PostObject` operation and returns the necessary form data when
  executing the `PostObject` operation.

  Read more at:

    * [PostObject](https://www.alibabacloud.com/help/en/oss/developer-reference/postobject/)
    * [PostObject (zh-Hans)](https://help.aliyun.com/zh/oss/developer-reference/postobject/)

  ## Adding signature

  This implementation has built-in OSS4 signature support.

  > V1 signature is not supported.

  ## Examples

      region = "oss-us-west-1"
      bucket = "example-bucket"

      key = "lenna.png"
      acl = "private"
      max_size_in_bytes = 1024 * 1024 * 5

      conditions = [
        ["eq", "$key", key],
        ["eq", "$x-oss-object-acl", acl],
        ["content-length-range", 1, max_size_in_bytes]
      ]

      seconds_to_expire = 3600

      opts = [
        access_key_id: "...",
        access_key_secret: "...",
        region: region,
        bucket: bucket
      ]

      %{
        policy: policy,
        "x-oss-signature-version": x_oss_signature_version,
        "x-oss-credential": x_oss_credential,
        "x-oss-date": x_oss_date,
        "x-oss-signature": x_oss_signature,
      } = presign_post_object(conditions, seconds_to_expire, opts)

  To use the returned data, you should built a form with multipart data, and send it:

      alias Tesla.Multipart

      url = "https://#{bucket}.#{region}.aliyuncs.com"

      multipart =
        Multipart.new()
        |> Multipart.add_field("key", key)
        |> Multipart.add_field("x-oss-object-acl", acl)
        |> Multipart.add_field("policy", policy)
        |> Multipart.add_field("x-oss-credential", x_oss_credential)
        |> Multipart.add_field("x-oss-date", x_oss_date)
        |> Multipart.add_field("x-oss-signature-version", x_oss_signature_version)
        |> Multipart.add_field("x-oss-signature", x_oss_signature)
        |> Multipart.add_file_content(binary_of_file, "lenna.png")

      {:ok, %{status: 204}} = Tesla.post(url, multipart)

  """
  @spec presign_post_object(list(), pos_integer(), sign_opts()) :: %{
          policy: String.t(),
          "x-oss-signature-version": String.t(),
          "x-oss-credential": String.t(),
          "x-oss-date": String.t(),
          "x-oss-signature": String.t()
        }
  def presign_post_object(conditions, seconds_to_expire, opts)
      when is_list(conditions) and is_integer(seconds_to_expire) do
    opts =
      opts
      |> NimbleOptions.validate!(@sign_opts_definition)
      |> Map.new()

    %{
      signature_version: signature_version,
      credential: credential,
      datetime: datetime,
      at: at
    } = Signature.OSS4.prepare_sign_info_for_post_policy(opts)

    post_policy = %PostPolicy{
      expiration: build_expiration(at, seconds_to_expire),
      conditions: [
        %{bucket: opts.bucket},
        %{"x-oss-signature-version": signature_version},
        %{"x-oss-credential": credential},
        %{"x-oss-date": datetime}
        | conditions
      ]
    }

    %{
      post_policy: post_policy,
      signature: signature
    } = Signature.OSS4.sign(post_policy, opts)

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
