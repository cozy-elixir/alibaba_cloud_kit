defmodule FileStoreTest do
  use ExUnit.Case

  @example_image_binary "../files/lenna.png"
                        |> Path.expand(__DIR__)
                        |> File.read!()

  setup do
    Application.put_env(:demo, FileStore,
      access_key_id: System.fetch_env!("TEST_ACCESS_KEY_ID"),
      access_key_secret: System.fetch_env!("TEST_ACCESS_KEY_SECRET"),
      region: System.fetch_env!("TEST_OSS_REGION"),
      bucket: System.fetch_env!("TEST_OSS_BUCKET")
    )

    :ok
  end

  @tag external: true
  test "manage files" do
    key = "examples/file_store/temporary/lenna woman.png"
    assert {:ok, _key} = FileStore.put_file(key, @example_image_binary)
    assert {:ok, _data} = FileStore.get_file(key)
    assert {:ok, _key} = FileStore.delete_file(key)
    assert :error = FileStore.get_file(key)
  end

  @tag external: true
  test "generates a signed URL which can be accessed in Web browser" do
    key = "examples/file_store/persistent/lenna woman.png"
    {:ok, key} = FileStore.put_file(key, @example_image_binary)
    url = FileStore.get_access_url(key)
    assert {:ok, %{status: 200}} = Tesla.get(url)
  end

  @tag external: true
  test "presigns a file and uploading a file with related information" do
    alias Tesla.Multipart

    key = "examples/file_store/presign/lenna woman.png"

    %{
      endpoint: endpoint,
      method: method,
      fields: fields
    } = FileStore.presign_file(key)

    multipart =
      Multipart.new()
      |> then(
        &Enum.reduce(fields, &1, fn {k, v}, multipart ->
          Multipart.add_field(multipart, k, v)
        end)
      )
      |> Multipart.add_file_content(@example_image_binary, Path.basename(fields.key))

    assert {:ok, %{status: 204}} =
             Tesla.request(
               method: method,
               url: endpoint,
               body: multipart
             )
  end

  @tag external: true
  test "presigns a file with OSS v1 signature and uploading a file with related information" do
    alias Tesla.Multipart

    key = "examples/file_store/presign_v1/lenna woman.png"

    %{
      endpoint: endpoint,
      method: method,
      fields: fields
    } = FileStore.presign_file_v1(key)

    multipart =
      Multipart.new()
      |> then(
        &Enum.reduce(fields, &1, fn {k, v}, multipart ->
          Multipart.add_field(multipart, k, v)
        end)
      )
      |> Multipart.add_file_content(@example_image_binary, Path.basename(fields.key))

    assert {:ok, %{status: 204}} =
             Tesla.request(
               method: method,
               url: endpoint,
               body: multipart
             )
  end
end
