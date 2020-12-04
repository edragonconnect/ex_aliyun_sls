defmodule ExAliyunSls.ProducerTest do
  use ExUnit.Case
  alias ExAliyunSls.{Producer, LogMetric}

  @moduletag :capture_log

  doctest Producer

  test "package_timeout" do
    {:ok, producer} = Producer.start_link(package_timeout: 1000)
    log_item = LogMetric.make_log_item("test_package_timeout", [], 1)
    Producer.add_log_item(producer, log_item)
    Process.sleep(100)
    assert Producer.get_logs(producer) == {:ok, 1, [log_item]}
    Process.sleep(1500)
    assert Producer.get_logs(producer) == {:ok, 0, []}
  end

  test "package_count" do
    {:ok, producer} = Producer.start_link(package_count: 5)

    log_items = Enum.map(1..4, &LogMetric.make_log_item("test_package_count", [], &1))
    Producer.add_log_items(producer, log_items)
    log_items = Enum.reverse(log_items)
    Process.sleep(100)
    assert Producer.get_logs(producer) == {:ok, 4, log_items}

    log_item = LogMetric.make_log_item("test_package_count", [], 5)
    Producer.add_log_item(producer, log_item)
    Process.sleep(100)
    assert Producer.get_logs(producer) == {:ok, 0, []}
  end
end
