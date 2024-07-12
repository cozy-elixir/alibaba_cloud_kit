defmodule FileStore do
  @moduledoc """
  An example module provides basic API to operate files.
  """

  alias HTTPSpec.Request
  alias AlibabaCloudKit.OSS

  def put_file(key, data) when is_binary(key) and is_binary(key) do
    request =
      build_request(
        method: :put,
        path: Path.join("/", key),
        body: data
      )

    opts = build_opts(sign_type: :header)

    request
    |> OSS.sign_request!(opts)
    |> send_request()
    |> case do
      {:ok, %{status: 200}} -> {:ok, key}
      _ -> :error
    end
  end

  def get_file(key) when is_binary(key) do
    request =
      build_request(
        method: :get,
        path: Path.join("/", key)
      )

    opts = build_opts(sign_type: :header)

    request
    |> OSS.sign_request!(opts)
    |> send_request()
    |> case do
      {:ok, %{status: 200, body: data}} -> {:ok, data}
      _ -> :error
    end
  end

  def delete_file(key) when is_binary(key) do
    request =
      build_request(
        method: :delete,
        path: Path.join("/", key)
      )

    opts = build_opts(sign_type: :header)

    request
    |> OSS.sign_request!(opts)
    |> send_request()
    |> case do
      {:ok, %{status: 204}} -> {:ok, key}
      _ -> :error
    end
  end

  def get_access_url(key) when is_binary(key) do
    request =
      build_request(
        method: :get,
        path: Path.join("/", key),
        query: "x-oss-expires=300"
      )

    opts = build_opts(sign_type: :query)

    request
    |> OSS.sign_request!(opts)
    |> Request.build_url()
  end

  @acl "private"
  @max_size_in_bytes 1024 * 1024 * 100
  @seconds_to_expire 1800

  def presign_file(key) when is_binary(key) do
    conditions = [
      ["eq", "$key", key],
      ["eq", "$x-oss-object-acl", @acl],
      ["content-length-range", 1, @max_size_in_bytes]
    ]

    opts = build_opts()

    endpoint = "https://#{opts[:bucket]}.#{opts[:region]}.aliyuncs.com"

    %{
      policy: policy,
      "x-oss-credential": x_oss_credential,
      "x-oss-date": x_oss_date,
      "x-oss-signature-version": x_oss_signature_version,
      "x-oss-signature": x_oss_signature
    } = OSS.Object.presign_post_object(conditions, @seconds_to_expire, opts)

    %{
      endpoint: endpoint,
      method: :post,
      fields: %{
        key: key,
        "x-oss-object-acl": @acl,
        policy: policy,
        "x-oss-credential": x_oss_credential,
        "x-oss-date": x_oss_date,
        "x-oss-signature-version": x_oss_signature_version,
        "x-oss-signature": x_oss_signature
      }
    }
  end

  defp build_request(overrides) when is_list(overrides) do
    config =
      :demo
      |> Application.fetch_env!(__MODULE__)
      |> Keyword.take([:region, :bucket])

    default = [
      scheme: :https,
      host: "#{config[:bucket]}.#{config[:region]}.aliyuncs.com",
      port: 443
    ]

    default
    |> Keyword.merge(overrides)
    |> Request.new!()
  end

  defp build_opts(overrides \\ []) when is_list(overrides) do
    :demo
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.take([:access_key_id, :access_key_secret, :region, :bucket])
    |> Keyword.merge(overrides)
  end

  defp send_request(url) when is_binary(url) do
    Tesla.get(url)
  end

  defp send_request(%HTTPSpec.Request{} = request) do
    Tesla.request(
      method: request.method,
      url: HTTPSpec.Request.build_url(request),
      headers: request.headers,
      body: request.body
    )
  end
end
