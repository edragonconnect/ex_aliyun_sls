defmodule ExAliyunSls.Log do
  @moduledoc false
  use Protobuf, from: Path.expand("./log_logs_raw.proto", __DIR__)
end
