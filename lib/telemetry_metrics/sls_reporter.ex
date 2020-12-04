defmodule Telemetry.Metrics.SLSReporter do
  @moduledoc false
  use GenServer
  require Logger
  alias ExAliyunSls.{LogMetric, Producer}

  def start_link(opts) do
    server_opts = Keyword.take(opts, [:name])

    metrics =
      opts[:metrics] ||
        raise ArgumentError, "the :metrics option is required by #{inspect(__MODULE__)}"

    producer_options = opts[:producer_options] || []

    GenServer.start_link(__MODULE__, {metrics, producer_options}, server_opts)
  end

  @impl true
  def init({metrics, producer_options}) do
    Process.flag(:trap_exit, true)
    {:ok, producer} = Producer.start_link(producer_options)
    groups = Enum.group_by(metrics, & &1.event_name)

    for {event, metrics} <- groups do
      id = {__MODULE__, event, self()}
      metrics = Enum.map(metrics, &{Enum.join(&1.name, "_"), &1})
      :telemetry.attach(id, event, &handle_event/4, {metrics, producer})
    end

    {:ok, Map.keys(groups)}
  end

  @impl true
  def handle_info({:DOWN, _ref, _, pid, reason}, _) do
    raise "producer #{inspect(pid)} exited: " <> Exception.format_exit(reason)
  end

  @impl true
  def terminate(_, events) do
    for event <- events do
      :telemetry.detach({__MODULE__, event, self()})
    end

    :ok
  end

  defp handle_event(_event_name, measurements, metadata, {metrics, producer}) do
    metrics
    |> Enum.reduce([], fn {metric_name, metric}, acc ->
      try do
        measurement = extract_measurement(metric, measurements, metadata)
        tags = extract_tags(metric, metadata)

        cond do
          is_nil(measurement) -> acc
          not keep?(metric, metadata) -> acc
          true -> [LogMetric.make_log_item(metric_name, tags, measurement) | acc]
        end
      rescue
        e ->
          Logger.warn([
            "Could not format metric #{inspect(metric)}\n",
            Exception.format(:error, e, __STACKTRACE__)
          ])

          acc
      end
    end)
    |> case do
      [] -> :skip
      log_items -> Producer.add_log_items(producer, log_items)
    end
  end

  defp keep?(%{keep: nil}, _metadata), do: true
  defp keep?(metric, metadata), do: metric.keep.(metadata)

  defp extract_measurement(metric, measurements, metadata) do
    case metric.measurement do
      fun when is_function(fun, 2) -> fun.(measurements, metadata)
      fun when is_function(fun, 1) -> fun.(measurements)
      key -> measurements[key]
    end
  end

  defp extract_tags(metric, metadata) do
    tag_values = metric.tag_values.(metadata)
    Map.take(tag_values, metric.tags)
  end
end
