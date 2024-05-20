defmodule CozyAliyunOpenAPI.ConfigTest do
  use ExUnit.Case
  alias CozyAliyunOpenAPI.Config

  describe "new!/1" do
    test "creates a %Config{} struct" do
      assert %Config{access_key_id: _, access_key_secret: _} =
               Config.new!(
                 access_key_id: "...",
                 access_key_secret: "..."
               )
    end

    test "raises error when required keys are missing" do
      assert_raise NimbleOptions.ValidationError,
                   "required :access_key_id option not found, received options: []",
                   fn ->
                     Config.new!([])
                   end

      assert_raise NimbleOptions.ValidationError,
                   "required :access_key_secret option not found, received options: [:access_key_id]",
                   fn ->
                     Config.new!(access_key_id: "...")
                   end
    end
  end
end
