# AlibabaCloudKit

[![CI](https://github.com/cozy-elixir/alibaba_cloud_kit/actions/workflows/ci.yml/badge.svg)](https://github.com/cozy-elixir/alibaba_cloud_kit/actions/workflows/ci.yml)
[![Hex.pm](https://img.shields.io/hexpm/v/alibaba_cloud_kit.svg)](https://hex.pm/packages/alibaba_cloud_kit)

A kit for Alibaba Cloud or Aliyun.

## Notes

This package is still in its early stages, so it may still undergo significant changes, potentially leading to breaking changes.

## Installation

Add `:alibaba_cloud_kit` to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:alibaba_cloud_kit, "<requirement>"}
  ]
end
```

## Usage

For more information, see the [documentation](https://hexdocs.pm/alibaba_cloud_kit).

## Tests

Run basic tests:

```console
$ mix test
```

Run all tests:

```console
$ export TEST_ACCESS_KEY_ID=...
$ export TEST_ACCESS_KEY_SECRET=...
$ export TEST_OSS_REGION=...
$ export TEST_OSS_BUCKET=...

$ mix test --include external:true
```

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
