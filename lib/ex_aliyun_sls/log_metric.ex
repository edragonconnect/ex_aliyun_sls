defmodule ExAliyunSls.LogMetric do
  @moduledoc false
  alias ExAliyunSls.Log

  def make_log_item(metric_name, labels, value, time_nano \\ System.system_time(:nanosecond)) do
    labels = if is_binary(labels), do: labels, else: format_labels(labels)

    %Log{
      Contents: [
        %Log.Content{Key: "__name__", Value: metric_name},
        %Log.Content{Key: "__labels__", Value: labels},
        %Log.Content{Key: "__value__", Value: to_string(value)},
        %Log.Content{Key: "__time_nano__", Value: to_string(time_nano)}
      ],
      Time: System.convert_time_unit(time_nano, :nanosecond, :second)
    }
  end

  def format_labels(labels),
    do: labels |> Enum.map(fn {k, v} -> "#{k}#$##{v}" end) |> Enum.join("|")
end
