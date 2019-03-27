defmodule ExAliyunSls.Utils do
  def iterate_struct_to_map(%_{} = data) do
    data
    |> Map.keys()
    |> Enum.filter(fn key -> key != :__struct__ end)
    |> Enum.reduce(%{}, fn key, acc ->
      value = Map.get(data, key)

      updated_value =
        case is_map(value) do
          true ->
            iterate_struct_to_map(value)

          false ->
            value
        end

      Map.put(acc, key, updated_value)
    end)
  end

  def iterate_struct_to_map(data) when is_map(data) do
    Enum.reduce(data, %{}, fn {key, value}, acc ->
      cond do
        Keyword.keyword?(value) ->
          updated_value =
            Enum.reduce(value, Keyword.new(), fn {inner_key, inner_value}, acc ->
              updated_inner_value = iterate_struct_to_map(inner_value)
              Keyword.put(acc, inner_key, updated_inner_value)
            end)

          Map.put(acc, key, updated_value)

        is_list(value) ->
          updated_value =
            Enum.reduce(value, [], fn item, acc ->
              Enum.concat(acc, [iterate_struct_to_map(item)])
            end)

          Map.put(acc, key, updated_value)

        is_map(value) ->
          updated_value = iterate_struct_to_map(value)
          Map.put(acc, key, updated_value)

        true ->
          Map.put(acc, key, value)
      end
    end)
  end

  def iterate_struct_to_map(data) do
    data
  end
end
