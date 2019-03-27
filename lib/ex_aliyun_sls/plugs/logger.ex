defmodule ExAliyunSls.Plug.Logger do
  @moduledoc false

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
    |> ExAliyunSls.Utils.iterate_struct_to_map()
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
end
