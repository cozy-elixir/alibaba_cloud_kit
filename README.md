# CozyAliyunOpenAPI

[![Hex.pm](https://img.shields.io/hexpm/v/cozy_aliyun_open_api.svg)](https://hex.pm/packages/cozy_aliyun_open_api)

> An SDK builder for Aliyun OpenAPI.

This package is an SDK builder. It provides utilities to reduce the cost of creating an SDK, such as:

- building requests
- signing requests
- sending requests
- converting the XML content or JSON content in the response to a map with snake-cased keys
- ...

It doesn't provide one-to-one mapping against all available APIs provided by Aliyun OpenAPI. See the reason in [FAQ](#faq).

## Installation

Add `:cozy_aliyun_open_api` to the list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:cozy_aliyun_open_api, "~> <version>"}
  ]
end
```

## Usage

For more information, see the [documentation](https://hexdocs.pm/cozy_aliyun_open_api/CozyAliyunOpenAPI.html).

## FAQ

### Why not providing one-to-one mapping against all available APIs?

Because:

- It's hard to do the mapping automatically:
  - The official API documentation isn't structured data.
  - It's hard to parse and map them to API requests.
- It's hard to do the mapping manually:
  - It's a tedius work.
  - It's error-prone.

And, in real apps, it's rare that all available APIs are required. In general, only a few API are required. So, mapping what is required is acceptable.

The simpler, the better.

## License

[Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0)
