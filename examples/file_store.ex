defmodule FileStore do
  @moduledoc """
  An example module provides basic API to operate files.
  """

  alias CozyAliyunOpenAPI.Config
  alias CozyAliyunOpenAPI.Specs.OSS
  alias CozyAliyunOpenAPI.Specs.OSS.Object
  alias CozyAliyunOpenAPI.HTTPRequest
  alias CozyAliyunOpenAPI.HTTPClient

  def put_file(path, data) when is_binary(path) and is_binary(data) do
    response =
      OSS.new!(config(), %{
        sign_type: :header,
        region: region(),
        bucket: bucket(),
        endpoint: endpoint(),
        method: :put,
        path: path,
        body: data
      })
      |> HTTPRequest.from_spec!()
      |> HTTPClient.request()

    with {:ok, 200, _headers, _body} <- response do
      {:ok, path}
    end
  end

  def get_file(path) when is_binary(path) do
    response =
      OSS.new!(config(), %{
        sign_type: :header,
        region: region(),
        bucket: bucket(),
        endpoint: endpoint(),
        method: :get,
        path: path
      })
      |> HTTPRequest.from_spec!()
      |> HTTPClient.request()

    with {:ok, 200, _headers, _body} <- response do
      {:ok, path}
    end
  end

  def delete_file(path) when is_binary(path) do
    response =
      OSS.new!(config(), %{
        sign_type: :header,
        region: region(),
        bucket: bucket(),
        endpoint: endpoint(),
        method: :delete,
        path: path
      })
      |> HTTPRequest.from_spec!()
      |> HTTPClient.request()

    with {:ok, 204, _headers, _body} <- response do
      {:ok, path}
    end
  end

  def get_access_url(path) when is_binary(path) do
    OSS.new!(config(), %{
      sign_type: :url,
      region: region(),
      bucket: bucket(),
      endpoint: endpoint(),
      method: :get,
      path: path,
      query: %{
        "x-oss-expires" => 300
      }
    })
    |> HTTPRequest.from_spec!()
    |> HTTPRequest.url()
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

    endpoint = "https://#{bucket()}.#{region()}.aliyuncs.com"

    %{
      endpoint: endpoint,
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
    |> Enum.into(%{})
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
