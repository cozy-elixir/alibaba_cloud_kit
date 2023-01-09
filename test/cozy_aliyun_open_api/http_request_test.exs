defmodule CozyAliyunOpenAPI.HTTPRequestTest do
  use ExUnit.Case
  alias CozyAliyunOpenAPI.HTTPRequest

  describe "new!/2" do
    test "creates an HTTP request struct" do
      assert %HTTPRequest{} =
               HTTPRequest.new!(%{
                 scheme: :https,
                 host: "example.com",
                 port: 443,
                 method: :get
               })
    end
  end
end
