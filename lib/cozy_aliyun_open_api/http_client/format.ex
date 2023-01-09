defmodule CozyAliyunOpenAPI.HTTPClient.Format do
  @moduledoc false

  @doc """
  Converts XML string to a map.
  """
  if Code.ensure_loaded?(SAXMap) do
    @spec convert_xml_to_map!(String.t()) :: map()
    def convert_xml_to_map!(xml_string) do
      case SAXMap.from_string(xml_string) do
        {:ok, map} ->
          to_snake_case(map)

        _ ->
          raise ArgumentError, "invalid XML string"
      end
    end
  else
    @spec convert_xml_to_map!(String.t()) :: map()
    def convert_xml_to_map!(_xml_string) do
      require Logger

      Logger.error("""
      Could not find sax_map dependency.

      Please add :sax_map to your dependencies:

          {:sax_map, "~> 1.0"}

      """)

      raise "missing sax_map dependency"
    end
  end

  @doc """
  Converts JSON string to a map.
  """
  @spec convert_json_to_map!(String.t()) :: map()
  def convert_json_to_map!(json_string) do
    json_string
    |> CozyAliyunOpenAPI.json_library().decode!()
    |> to_snake_case()
  end

  # Converts all the keys in a map to snake case.

  # If the map is a struct with no `Enumerable` implementation, the struct is considered to be a single value.

  # The code is borrowed from:
  # https://github.com/johnnyji/proper_case/blob/9dc5462d458b767a995ae8b22f9b906e8e80e4a4/lib/proper_case.ex#L89
  defp to_snake_case(map) when is_map(map) do
    try do
      for {key, val} <- map,
          into: %{},
          do: {snake_case(key), to_snake_case(val)}
    rescue
      # not Enumerable
      Protocol.UndefinedError -> map
    end
  end

  defp to_snake_case(list) when is_list(list) do
    Enum.map(list, &to_snake_case/1)
  end

  defp to_snake_case(other), do: other

  defp snake_case(value) when is_atom(value) do
    value
    |> Atom.to_string()
    |> Macro.underscore()
  end

  defp snake_case(value) when is_number(value) do
    value
  end

  defp snake_case(value) when is_binary(value) do
    value
    |> String.replace(" ", "")
    |> Macro.underscore()
  end
end
