defmodule CozyAliyunOpenAPI.EasyTime do
  @moduledoc false

  @type time_unit :: :native | :microsecond | :millisecond | :second

  @spec utc_now(time_unit()) :: DateTime.t()
  def utc_now(time_unit), do: DateTime.utc_now(time_unit)

  @spec utc_today() :: Date.t()
  def utc_today(), do: Date.utc_today()

  @spec to_rfc1123(DateTime.t()) :: String.t()
  def to_rfc1123(date_time),
    do: Calendar.strftime(date_time, "%a, %d %b %Y %H:%M:%S GMT")

  @spec to_basic_iso8601(DateTime.t() | Date.t()) :: String.t()

  def to_basic_iso8601(%DateTime{} = date_time), do: DateTime.to_iso8601(date_time, :basic)

  def to_basic_iso8601(%Date{} = date), do: Date.to_iso8601(date, :basic)

  @spec to_extended_iso8601(DateTime.t() | Date.t()) :: String.t()
  def to_extended_iso8601(%DateTime{} = date_time), do: DateTime.to_iso8601(date_time, :extended)

  def to_extended_iso8601(%Date{} = date), do: Date.to_iso8601(date, :extended)
end
