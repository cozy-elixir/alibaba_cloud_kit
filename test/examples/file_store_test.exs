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

  test "manage files" do
    remote_path = "examples/file_store/temporary/lenna.png"
    assert {:ok, _path} = FileStore.put_file(remote_path, @example_image_binary)
    assert {:ok, _data} = FileStore.get_file(remote_path)
    assert {:ok, _path} = FileStore.delete_file(remote_path)
    assert :error = FileStore.get_file(remote_path)
  end

  test "generates a signed URL which can be accessed in Web browser" do
    remote_path = "examples/file_store/persistent/lenna.png"
    {:ok, path} = FileStore.put_file(remote_path, @example_image_binary)
    url = FileStore.get_access_url(path)

    assert {:ok, %{status: 200}} = Tesla.get(url)
  end

  test "presigns a file and uploading a file with related information" do
    alias Tesla.Multipart

    remote_path = "examples/file_store/presign/lenna.png"

    %{
      endpoint: endpoint,
      method: method,
      fields: fields
    } = FileStore.presign_file(remote_path)

    mp =
      Multipart.new()
      |> then(
        &Enum.reduce(fields, &1, fn {k, v}, multipart ->
          Multipart.add_field(multipart, k, v)
        end)
      )
      |> Multipart.add_file_content(@example_image_binary, Path.basename(fields.key))

    assert {:ok, %{status: 204}} = Tesla.request(method: method, url: endpoint, body: mp)
  end
end
