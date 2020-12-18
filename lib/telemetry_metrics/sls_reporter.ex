defmodule Telemetry.Metrics.SLSReporter do
  @moduledoc false
  use GenServer
  require Logger
  alias ExAliyunSls.{LogMetric, Producer}
  alias Telemetry.Metrics.Distribution
  alias TelemetryMetricsPrometheus.{Core, Core.Aggregator, Core.Registry}

  def start_link(opts) do
    server_opts = Keyword.take(opts, [:name])

    metrics =
      opts[:metrics] ||
        raise ArgumentError, "the :metrics option is required by #{inspect(__MODULE__)}"

    producer_options = opts[:producer_options] || [package_timeout: 20_000, package_count: 1_000]
    interval = opts[:interval] || 5_000

    GenServer.start_link(
      __MODULE__,
      %{metrics: metrics, producer_options: producer_options, interval: interval},
      server_opts
    )
  end

  @impl true
  def init(%{metrics: metrics, producer_options: producer_options, interval: interval}) do
    Process.flag(:trap_exit, true)
    {:ok, core} = Core.start_link(metrics: metrics)
    {:ok, producer} = Producer.start_link(producer_options)
    Process.send_after(self(), :init_report, interval)
    {:ok, %{producer: producer, core: core, interval: interval}}
  end

  @impl true
  def handle_info(:init_report, %{producer: producer, core: core, interval: interval} = state) do
    Process.send_after(self(), :report, interval)
    config = Registry.config(core)
    metrics = Registry.metrics(core)
    name_metrics = Enum.map(metrics, &{Enum.join(&1.name, "_"), &1})
    scrape(producer, config, name_metrics, metrics)
    {:noreply, Map.merge(state, %{config: config, metrics: metrics, name_metrics: name_metrics})}
  end

  def handle_info(
        :report,
        %{
          producer: producer,
          config: config,
          name_metrics: name_metrics,
          metrics: metrics,
          interval: interval
        } = state
      ) do
    Process.send_after(self(), :report, interval)
    scrape(producer, config, name_metrics, metrics)
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, _, pid, reason}, %{producer: pid}) do
    raise "producer #{inspect(pid)} exited: " <> Exception.format_exit(reason)
  end

  def handle_info({:DOWN, _ref, _, pid, reason}, %{core: pid}) do
    raise "core #{inspect(pid)} exited: " <> Exception.format_exit(reason)
  end

  defp scrape(producer, config, name_metrics, metrics) do
    aggregates_table_id = config.aggregates_table_id
    :ok = Aggregator.aggregate(metrics, aggregates_table_id, config.dist_table_id)
    time_series = Aggregator.get_time_series(aggregates_table_id)

    log_items =
      Enum.flat_map(name_metrics, fn
        {metric_name, %Distribution{name: name}} ->
          # histogram
          time_series[name]
          |> List.wrap()
          |> Enum.flat_map(fn {{_, labels}, {buckets, count, sum}} ->
            labels = LogMetric.format_labels(labels)

            Enum.map(
              buckets,
              fn {upper_bound, count} ->
                LogMetric.make_log_item(
                  metric_name <> "_bucket",
                  labels <> "|le#$##{upper_bound}",
                  count
                )
              end
            ) ++
              [
                LogMetric.make_log_item(metric_name <> "_sum", labels, sum),
                LogMetric.make_log_item(metric_name <> "_count", labels, count)
              ]
          end)

        {metric_name, %{name: name}} ->
          time_series[name]
          |> List.wrap()
          |> Enum.map(fn {{_, labels}, value} ->
            LogMetric.make_log_item(metric_name, labels, value)
          end)
      end)

    Producer.add_log_items(producer, log_items)
  end
end
