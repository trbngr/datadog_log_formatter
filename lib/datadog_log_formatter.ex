defmodule DatadogLogFormatter do
  def format(level, message, timestamp, metadata) do
    options =
      Application.get_env(:logger, :datadog_log_formatter, service: :elixir, environment: nil)

    {:ok, hostname} = :inet.gethostname()

    metadata = normalize(metadata)

    message =
      case message do
        message when is_list(message) -> IO.iodata_to_binary(message)
        message -> message
      end

    values = %{
      message: message,
      level: level,
      source: :elixir,
      timestamp: datetime(timestamp),
      host: List.to_string(hostname),
      service: options[:service]
    }

    case options[:environment] do
      nil -> values
      environment -> Map.put(values, :environment, environment)
    end

    message =
      values
      |> Map.merge(metadata)
      |> Jason.encode_to_iodata!()

    message ++ [?\n]
  end

  def normalize(meta) when is_list(meta) do
    if Keyword.keyword?(meta) do
      meta
      |> Enum.into(%{})
      |> normalize()
    else
      Enum.map(meta, &normalize/1)
    end
  end

  def normalize(%{__struct__: type} = map) do
    map
    |> Map.from_struct()
    |> Map.merge(%{type: type})
    |> normalize()
  end

  def normalize(map) when is_map(map),
    do: Enum.reduce(map, %{}, fn {key, value}, acc -> Map.put(acc, key, normalize(value)) end)

  def normalize(string) when is_binary(string), do: string

  def normalize(other), do: inspect(other)

  defp datetime({{year, month, day}, {hour, min, sec, millis}}) do
    {:ok, ndt} = NaiveDateTime.new(year, month, day, hour, min, sec, {millis * 1000, 3})
    NaiveDateTime.to_iso8601(ndt) <> timezone()
  end

  defp timezone() do
    offset = timezone_offset()
    minute = offset |> abs() |> rem(3600) |> div(60)
    hour = offset |> abs() |> div(3600)
    sign(offset) <> zero_pad(hour, 2) <> ":" <> zero_pad(minute, 2)
  end

  defp timezone_offset() do
    t_utc = :calendar.universal_time()
    t_local = :calendar.universal_time_to_local_time(t_utc)

    s_utc = :calendar.datetime_to_gregorian_seconds(t_utc)
    s_local = :calendar.datetime_to_gregorian_seconds(t_local)

    s_local - s_utc
  end

  defp sign(total) when total < 0, do: "-"
  defp sign(_), do: "+"

  defp zero_pad(val, count) do
    num = Integer.to_string(val)
    :binary.copy("0", count - byte_size(num)) <> num
  end
end
