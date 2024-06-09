defmodule AliyunOpenAPI.HTTP.RequestTest do
  use ExUnit.Case
  alias AliyunOpenAPI.HTTP.Request

  describe "new!/2" do
    test "creates an HTTP request struct" do
      assert %Request{} =
               Request.new!(%{
                 scheme: :https,
                 host: "example.com",
                 port: 443,
                 method: :get
               })
    end
  end
end
