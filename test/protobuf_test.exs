defmodule ExAliyunSls.ProtobufTest do
  use ExUnit.Case, async: false

  alias ExAliyunSls.{Log, LogTag, LogGroup}

  def build_item do
    item_key = "test_item_key"
    item_value = "test_item_value: Protocol buffers are Google's
      language-neutral, platform-neutral, extensible mechanism for
      serializing structured data – think XML, but smaller, faster,
      and simpler. You define how you want your data to be structured
      once, then you can use special generated source code to
      easily write and read your structured data to and from a
      variety of data streams and using a variety of languages."

    tag_key = "test_tag_key"
    tag_value = "Protocol Buffers - Google's data interchange format"

    timestamp = 424_314_210

    logitems = [
      %Log{
        Time: timestamp,
        Contents: [
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value}
        ]
      },
      %Log{
        Time: timestamp,
        Contents: [
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value}
        ]
      },
      %Log{
        Time: timestamp,
        Contents: [
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value}
        ]
      },
      %Log{
        Time: timestamp,
        Contents: [
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value}
        ]
      },
      %Log{
        Time: timestamp,
        Contents: [
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value}
        ]
      },
      %Log{
        Time: timestamp,
        Contents: [
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value},
          %Log.Content{Key: item_key, Value: item_value}
        ]
      }
    ]

    logtags = [
      %LogTag{Key: tag_key, Value: tag_value},
      %LogTag{Key: tag_key, Value: tag_value},
      %LogTag{Key: tag_key, Value: tag_value}
    ]

    %LogGroup{Logs: logitems, Source: "", LogTags: logtags, Topic: ""}
  end

  def run_encode(group) do
    {:ok, encoded, _size} = LogGroup.encode(group)
    :erlang.iolist_to_binary(encoded)
  end

  def run_decode(body) do
    {:ok, log_group} = LogGroup.decode(body)
    log_group
  end

  test "timer encode and decode" do
    log_group = build_item()
    decoded = log_group |> run_encode() |> run_decode()
    assert log_group == decoded
  end
end
