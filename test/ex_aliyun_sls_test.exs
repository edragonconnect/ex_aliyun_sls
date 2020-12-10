defmodule ExAliyunSlsTest do
  use ExUnit.Case, async: false

  require Logger

  @backend {ExAliyunSls.LoggerBackend, :sls}

  alias ExAliyunSls.Client
  alias ExAliyunSls.{Log, LogTag, LoggerBackend, Utils}

  import LoggerBackend, only: [metadata_matches?: 2]

  setup do
    LoggerBackend.empty_package()
  end

  test "build one log" do
    Agent.start_link(fn -> Utils.get_source() end, name: :source)
    Agent.start_link(fn -> [] end, name: :log_package)
    Agent.start_link(fn -> 0 end, name: :log_count)
    timestamp = now_timestamp()
    result = LoggerBackend.build_one_log(:info, "test", timestamp, [])

    log = %Log{
      Contents: [
        %Log.Content{Key: "level", Value: "info"},
        %Log.Content{Key: "msg", Value: "test"}
      ],
      Time: timestamp
    }

    assert result == log
  end

  test "put logs" do
    log_items = [
      Log.new(
        Time: now_timestamp(),
        Contents: [
          Log.Content.new(Key: "file", Value: "ex_aliyun_sls/lib/ex_aliyun_sls/client.ex"),
          Log.Content.new(Key: "cc", Value: "cc1")
        ]
      ),
      Log.new(Time: now_timestamp(), Contents: [Log.Content.new(Key: "aa1", Value: "bb1")]),
      Log.new(Time: now_timestamp(), Contents: [Log.Content.new(Key: "aa", Value: "bb2")])
    ]

    log_tags = [
      LogTag.new(Key: "haha", Value: "hehe"),
      LogTag.new(Key: "hey", Value: "test")
    ]

    topic = "topic_test"
    source = Utils.get_source()
    profile = Utils.get_profile()

    assert Client.push2log_store(log_items, log_tags, topic, source, profile) == {:ok, "success"}
  end

  test "metadata_matches?" do
    assert metadata_matches?([a: 1], a: 1) == true
    assert metadata_matches?([b: 1], a: 1) == false
    assert metadata_matches?([b: 1], nil) == true
    assert metadata_matches?([b: 1, a: 1], a: 1) == true
    assert metadata_matches?([c: 1, b: 1, a: 1], b: 1, a: 1) == true
    assert metadata_matches?([a: 1], b: 1, a: 1) == false
  end

  test "add log to package" do
    config(level: :debug)
    assert LoggerBackend.get_count() == 0
    Logger.info("test 1")
    Process.sleep(100)
    assert LoggerBackend.get_count() == 1
    Logger.debug("test 2")
    Logger.error("test 3")
    Process.sleep(100)
    assert LoggerBackend.get_count() == 3
  end

  test "LoggerBackend package_timeout setting" do
    assert LoggerBackend.get_count() == 0
    Logger.info("package_timeout start: #{System.system_time(:second)}")
    Process.sleep(5_100)
    assert LoggerBackend.get_count() == 0
  end

  test "LoggerBackend package_count setting" do
    assert LoggerBackend.get_count() == 0
    Enum.map(1..11, &Logger.info("package_count #{&1}"))
    Process.sleep(100)
    assert LoggerBackend.get_count() == 1
  end

  test "can configure log level" do
    config(level: :info)

    Logger.debug("hello")
    Process.sleep(100)
    assert LoggerBackend.get_count() == 0
  end

  defp now_timestamp, do: System.system_time(:second)

  defp config(opts) do
    Logger.configure_backend(@backend, opts)
  end
end
