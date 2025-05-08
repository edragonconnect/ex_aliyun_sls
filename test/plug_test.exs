defmodule ExAliyunSls.PlugTest do
  use ExUnit.Case, async: false

  import Plug.Test
  import ExUnit.CaptureLog

  require Logger

  defmodule MyPlug do
    use Plug.Builder

    plug(ExAliyunSls.Plug.Logger)
    plug(:passthrough)

    defp passthrough(conn, _) do
      Plug.Conn.send_resp(conn, 200, "Passthrough")
    end
  end

  defp call(conn) do
    MyPlug.call(conn, [])
  end

  defmodule MyChunkedPlug do
    use Plug.Builder

    plug(ExAliyunSls.Plug.Logger)
    plug(:passthrough)

    defp passthrough(conn, _) do
      Plug.Conn.send_chunked(conn, 200)
    end
  end

  defmodule MyHaltingPlug do
    use Plug.Builder, log_on_halt: :debug

    plug(:halter)
    defp halter(conn, _), do: halt(conn)
  end

  defmodule MyDebugLevelPlug do
    use Plug.Builder

    plug(Plug.Logger, log: :debug)
    plug(:passthrough)

    defp passthrough(conn, _) do
      Plug.Conn.send_resp(conn, 200, "Passthrough")
    end
  end

  test "logs proper message to console" do
    msg =
      capture_log(fn ->
        call(conn(:get, "/"))
      end)

    assert msg =~ "GET: /, Sent 200 in "
  end

  test "logs chunked if chunked reply" do
    msg =
      capture_log(fn ->
        MyChunkedPlug.call(conn(:get, "/hello/world"), [])
      end)

    assert msg =~ "GET: /hello/world, Chunked 200 in "
  end

  test "logs halted connections if :log_on_halt is true" do
    msg =
      capture_log(fn ->
        MyHaltingPlug.call(conn(:get, "/foo"), [])
      end)

    assert msg =~ "PlugTest.MyHaltingPlug halted in :halter/2"
  end
end
