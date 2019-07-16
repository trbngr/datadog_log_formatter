defmodule DatadogLogFormatter.Metadata do
  def normalize(meta, options) when is_list(meta) do
    filter_keys = options[:filter_keys]
    mask_keys = options[:mask_keys]

    meta
    |> normalize()
    |> mask(mask_keys)
    |> filter(filter_keys)
  end

  defp mask(%{__struct__: mod} = struct, keys) when is_atom(mod) do
    struct
    |> Map.from_struct()
    |> filter(keys)
  end

  defp mask(%{} = map, nil), do: map
  defp mask(%{} = map, list) when length(list) == 0, do: map

  defp mask(%{} = map, %{} = keys) do
    Enum.into(map, %{}, fn {k, v} ->
      case Map.get(keys, k) do
        {mod, fun} -> {k, apply(mod, fun, [v])}
        _ -> {k, mask(v, keys)}
      end
    end)
  end

  defp mask([_ | _] = list, keys) do
    Enum.map(list, &mask(&1, keys))
  end

  defp mask(other, _keys), do: other

  defp filter(%{__struct__: mod} = struct, keys) when is_atom(mod) do
    struct
    |> Map.from_struct()
    |> filter(keys)
  end

  defp filter(%{} = map, nil), do: map
  defp filter(%{} = map, keys) when length(keys) == 0, do: map

  defp filter(%{} = map, keys) do
    Enum.into(map, %{}, fn {k, v} ->
      if String.contains?(k, keys) do
        {k, "[FILTERED]"}
      else
        {k, filter(v, keys)}
      end
    end)
  end

  defp filter([_ | _] = list, keys) do
    Enum.map(list, &filter(&1, keys))
  end

  defp filter(other, _keys), do: other

  defp normalize(meta) when is_list(meta) do
    meta
    |> Enum.into(%{})
    |> Map.drop([:ansi_color, :pid])
    |> normalize()
  end

  defp normalize(%{__struct__: type} = map) do
    map
    |> Map.from_struct()
    |> Map.merge(%{type: type})
    |> normalize()
  end

  defp normalize(map) when is_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, acc ->
      Map.put(acc, to_string(key), normalize(value))
    end)
  end

  defp normalize(string) when is_binary(string), do: string

  defp normalize(other), do: inspect(other)
end
