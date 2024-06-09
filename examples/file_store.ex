defmodule FileStore do
  @moduledoc """
  An example module provides basic API to operate files.
  """

  alias AliyunOpenAPI.Config
  alias AliyunOpenAPI.Specs.OSS
  alias AliyunOpenAPI.Specs.OSS.Object
  alias AliyunOpenAPI.HTTP.Request
  alias AliyunOpenAPI.HTTP.Client

  def put_file(path, data) when is_binary(path) and is_binary(data) do
    response =
      OSS.new!(config(),
        sign_type: :header,
        region: region(),
        bucket: bucket(),
        endpoint: endpoint(),
        method: :put,
        path: path,
        body: data
      )
      |> Request.from_spec!()
      |> Client.request()

    with {:ok, %{status: 200}} <- response do
      {:ok, path}
    else
      _ ->
        :error
    end
  end

  def get_file(path) when is_binary(path) do
    response =
      OSS.new!(config(),
        sign_type: :header,
        region: region(),
        bucket: bucket(),
        endpoint: endpoint(),
        method: :get,
        path: path
      )
      |> Request.from_spec!()
      |> Client.request()

    with {:ok, %{status: 200}} <- response do
      {:ok, path}
    else
      _ ->
        :error
    end
  end

  def delete_file(path) when is_binary(path) do
    response =
      OSS.new!(config(),
        sign_type: :header,
        region: region(),
        bucket: bucket(),
        endpoint: endpoint(),
        method: :delete,
        path: path
      )
      |> Request.from_spec!()
      |> Client.request()

    with {:ok, %{status: 204}} <- response do
      {:ok, path}
    else
      _ ->
        :error
    end
  end

  def get_access_url(path) when is_binary(path) do
    OSS.new!(config(),
      sign_type: :url,
      region: region(),
      bucket: bucket(),
      endpoint: endpoint(),
      method: :get,
      path: path,
      query: %{
        "x-oss-expires" => 300
      }
    )
    |> Request.from_spec!()
    |> Request.url()
  end

  @acl "private"
  @max_size_in_bytes 1024 * 1024 * 100
  @seconds_to_expire 1800
  def presign_file(path) when is_binary(path) do
    conditions = [
      ["eq", "$key", path],
      ["eq", "$x-oss-object-acl", @acl],
      ["content-length-range", 1, @max_size_in_bytes]
    ]

    %{
      policy: policy,
      "x-oss-credential": x_oss_credential,
      "x-oss-date": x_oss_date,
      "x-oss-signature-version": x_oss_signature_version,
      "x-oss-signature": x_oss_signature
    } = Object.presign_post_object(config(), region(), bucket(), conditions, @seconds_to_expire)

    %{
      endpoint: endpoint(),
      method: :post,
      fields: %{
        key: path,
        "x-oss-object-acl": @acl,
        policy: policy,
        "x-oss-credential": x_oss_credential,
        "x-oss-date": x_oss_date,
        "x-oss-signature-version": x_oss_signature_version,
        "x-oss-signature": x_oss_signature
      }
    }
  end

  defp config do
    :demo
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.take([:access_key_id, :access_key_secret])
    |> Config.new!()
  end

  defp region do
    :demo
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:region)
  end

  defp bucket do
    :demo
    |> Application.fetch_env!(__MODULE__)
    |> Keyword.fetch!(:bucket)
  end

  defp endpoint do
    "https://#{bucket()}.#{region()}.aliyuncs.com"
  end
end
