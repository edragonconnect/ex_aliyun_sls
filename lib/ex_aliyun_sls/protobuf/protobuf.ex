defmodule ExAliyunSls.Log do
  @moduledoc """
  Protobuf module for AliyunSls.
  """
  use Protobuf, from: Path.expand("./log_logs_raw.proto", __DIR__)
end
