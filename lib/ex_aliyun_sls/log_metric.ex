defmodule ExAliyunSls.LogMetric do
  @moduledoc false
  alias ExAliyunSls.Log

  def make_log_item(metricName, labels, value, time_nano \\ System.system_time(:nanosecond)) do
    labels = labels |> Enum.map(fn {k, v} -> "#{k}#$##{v}" end) |> Enum.join("|")

    %Log{
      Contents: [
        %Log.Content{Key: "__name__", Value: metricName},
        %Log.Content{Key: "__labels__", Value: labels},
        %Log.Content{Key: "__value__", Value: to_string(value)},
        %Log.Content{Key: "__time_nano__", Value: to_string(time_nano)}
      ],
      Time: System.convert_time_unit(time_nano, :nanosecond, :second)
    }
  end
end
