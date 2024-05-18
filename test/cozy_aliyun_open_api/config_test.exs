defmodule CozyAliyunOpenAPI.ConfigTest do
  use ExUnit.Case
  alias CozyAliyunOpenAPI.Config

  describe "new!/1" do
    test "creates a %Config{} struct" do
      assert %Config{access_key_id: _, access_key_secret: _} =
               Config.new!(%{
                 access_key_id: "...",
                 access_key_secret: "..."
               })
    end

    test "raises ArgumentError when required keys are missing" do
      assert_raise ArgumentError,
                   "key :access_key_id, :access_key_secret should be provided",
                   fn ->
                     Config.new!(%{})
                   end
    end
  end
end
