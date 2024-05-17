defmodule CozyAliyunOpenAPI.EasyTimeBehaviour do
  @moduledoc false

  @type time_unit :: :native | :microsecond | :millisecond | :second
  @callback utc_now(time_unit()) :: DateTime.t()
  @callback utc_today() :: Date.t()
  @callback to_rfc1123(DateTime.t()) :: String.t()
  @callback to_basic_iso8601(DateTime.t()) :: String.t()
  @callback to_basic_iso8601(Date.t()) :: String.t()
end

defmodule CozyAliyunOpenAPI.EasyTimeImpl do
  @moduledoc false

  @behaviour CozyAliyunOpenAPI.EasyTimeBehaviour

  @impl true
  def utc_now(time_unit), do: DateTime.utc_now(time_unit)

  @impl true
  def utc_today(), do: Date.utc_today()

  @impl true
  def to_rfc1123(date_time),
    do: Calendar.strftime(date_time, "%a, %d %b %Y %H:%M:%S GMT")

  @impl true
  def to_basic_iso8601(%DateTime{} = date_time), do: DateTime.to_iso8601(date_time, :basic)

  @impl true
  def to_basic_iso8601(%Date{} = date), do: Date.to_iso8601(date, :basic)
end

defmodule CozyAliyunOpenAPI.EasyTime do
  @moduledoc false

  def utc_now(time_unit), do: impl().utc_now(time_unit)
  def utc_today(), do: impl().utc_today()
  def to_rfc1123(date_time), do: impl().to_rfc1123(date_time)
  def to_basic_iso8601(date_time_or_date), do: impl().to_basic_iso8601(date_time_or_date)

  defp impl() do
    Application.get_env(:cozy_aliyun_open_api, :easy_time, CozyAliyunOpenAPI.EasyTimeImpl)
  end
end
