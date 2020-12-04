defmodule ExAliyunSls.Producer do
  @moduledoc false
  use GenServer
  alias ExAliyunSls.{Client, Utils}

  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def add_log_item(pid, log_item), do: GenServer.cast(pid, {:add_item, log_item})
  def add_log_items(pid, log_items), do: GenServer.cast(pid, {:add_items, log_items})
  def get_logs(pid), do: GenServer.call(pid, :get_logs)
  def flush(pid), do: send(pid, :flush)

  @impl true
  def init(opts) do
    opts = Map.new(opts)
    package_count = Map.get(opts, :package_count, 100) - 1
    opts = Map.put(opts, :package_count, package_count)

    state =
      %{
        item_count: 0,
        log_items: [],
        package_timeout: 10_000,
        source: Utils.get_source(),
        profile: Utils.get_profile()
      }
      |> Map.merge(opts)

    Process.flag(:trap_exit, true)

    if is_integer(state.package_timeout) do
      Process.send_after(self(), :flush, state.package_timeout)
    end

    {:ok, state}
  end

  @impl true
  def handle_call(:get_logs, _from, state) do
    {:reply, {:ok, state.item_count, state.log_items}, state}
  end

  @impl true
  def handle_cast({:add_item, log_item}, state) do
    {:noreply, add_item(log_item, state)}
  end

  @impl true
  def handle_cast({:add_items, log_items}, state) do
    state = Enum.reduce(log_items, state, &add_item/2)
    {:noreply, state}
  end

  @impl true
  def handle_info(:flush, state) do
    send_logs(state)
    Process.send_after(self(), :flush, state.package_timeout)
    {:noreply, %{state | item_count: 0, log_items: []}}
  end

  @impl true
  def terminate(_reason, state) do
    if state.item_count > 0 do
      send_logs(state)
    end

    :ok
  end

  defp add_item(log_item, %{item_count: count, package_count: max} = state) when count < max do
    %{state | item_count: count + 1, log_items: [log_item | state.log_items]}
  end

  defp add_item(log_item, state) do
    send_logs(%{state | log_items: [log_item | state.log_items]})
    %{state | item_count: 0, log_items: []}
  end

  defp send_logs(state) do
    Task.start(fn ->
      Client.push2log_store(Enum.reverse(state.log_items), [], "", state.source, state.profile)
    end)
  end
end
