defmodule ExAliyunSls.Plug.Logger do
  @moduledoc """
  A logger `Plug`, you can use it instead of `Plug.Logger`` in your endpoint.
  """

  require Logger
  alias Plug.Conn

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    start = System.monotonic_time()
    level = Keyword.get(opts, :level, :info)

    Conn.register_before_send(conn, fn conn ->
      Logger.log(level, fn ->
        stop = System.monotonic_time()
        duration = (stop - start) |> get_duration
        status = conn.status
        state = conn.state
        request_path = conn.request_path
        method = conn.method

        connection_type =
          case state do
            :set_chunked -> "Chunked"
            _ -> "Sent"
          end

        msg = "#{method}: #{request_path}, #{connection_type} #{status} in #{duration}ms"

        {
          msg,
          [
            duration: duration,
            method: method,
            status: status,
            state: state,
            request_path: request_path,
            params: get_params(conn)
          ]
        }
      end)

      conn
    end)
  end

  defp get_duration(time) do
    time = time |> :erlang.convert_time_unit(:native, :micro_seconds)
    time / 1_000
  end

  defp get_params(%{params: _params = %Plug.Conn.Unfetched{}}), do: %{}

  defp get_params(%{params: params}) do
    params
    |> do_filter_params(Application.get_env(:ex_aliyun_sls, :backend)[:filtered_params])
    |> iterate_struct_to_map()
    |> Jason.encode!()
  end

  defp do_filter_params(params, nil), do: params

  defp do_filter_params(%{__struct__: mod} = struct, _params_to_filter) when is_atom(mod),
    do: struct

  defp do_filter_params(%{} = map, params_to_filter) do
    Enum.into(map, %{}, fn {k, v} ->
      if is_binary(k) && String.contains?(k, params_to_filter) do
        {k, "******"}
      else
        {k, do_filter_params(v, params_to_filter)}
      end
    end)
  end

  defp do_filter_params([_ | _] = list, params_to_filter),
    do: Enum.map(list, &do_filter_params(&1, params_to_filter))

  defp do_filter_params(other, _params_to_filter), do: other

  defp iterate_struct_to_map(%_{} = data) do
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

  defp iterate_struct_to_map(data) when is_map(data) do
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

  defp iterate_struct_to_map(data) do
    data
  end
end
