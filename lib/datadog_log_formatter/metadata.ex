defmodule DatadogLogFormatter.Metadata do
  def normalize(meta, filter_keys) when is_list(meta) do
    meta
    |> normalize_values()
    |> Enum.into(%{}, &filter_value(&1, filter_keys))
  end

  defp filter_value(kv, nil), do: kv
  defp filter_value(kv, []), do: kv

  defp filter_value({k, v}, keys) when is_binary(k) do
    cond do
      String.contains?(k, keys) -> {k, "[FILTERED]"}
      true -> {k, v}
    end
  end

  defp filter_value({k, v}, keys) when is_atom(k) do
    {k, v} = filter_value({Atom.to_string(k), v}, keys)
    {String.to_existing_atom(k), v}
  end

  defp normalize_values(meta) when is_list(meta) do
    if Keyword.keyword?(meta) do
      meta
      |> Enum.into(%{})
      |> Map.drop([:ansi_color, :pid])
      |> normalize_values()
    else
      Enum.map(meta, &normalize_values/1)
    end
  end

  defp normalize_values(%{__struct__: type} = map) do
    map
    |> Map.from_struct()
    |> Map.merge(%{type: type})
    |> normalize_values()
  end

  defp normalize_values(map) when is_map(map),
    do:
      Enum.reduce(map, %{}, fn {key, value}, acc ->
        Map.put(acc, key, normalize_values(value))
      end)

  defp normalize_values(string) when is_binary(string), do: string

  defp normalize_values(other), do: inspect(other)
end
