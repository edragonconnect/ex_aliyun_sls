defmodule ExAliyunSls.LoggerBackend do
  @moduledoc """
  The logger backend to send your logs to Aliyun Log Service by package.
  """

  @behaviour :gen_event

  @type level :: Logger.level()
  @type metadata :: [atom]

  alias ExAliyunSls.Log.LogRaw
  alias ExAliyunSls.Log.LogTagRaw
  alias ExAliyunSls.LoggerBackend.Client

  def init({__MODULE__, name}) do
    Process.flag(:trap_exit, true)

    Agent.start_link(fn -> {[], 0, 0} end, name: __MODULE__)
    {:ok, configure(name, [])}
  end

  def handle_call({:configure, opts}, %{name: name} = state) do
    {:ok, :ok, configure(name, opts, state)}
  end

  def handle_event(
        {level, _gl, {Logger, msg, ts, md}},
        %{level: min_level, metadata_filter: metadata_filter} = state
      ) do
    if (is_nil(min_level) or Logger.compare_levels(level, min_level) != :lt) and
         metadata_matches?(md, metadata_filter) do
      log_sls_event(level, msg, ts, md, state)
    else
      {:ok, state}
    end
  end

  def handle_event(:flush, state) do
    # We're not buffering anything so this is a no-op
    {:ok, state}
  end

  def handle_info(:clear_current_package, state) do
    clear_current_package(state)
    {:ok, state}
  end

  def handle_info({:DOWN, ref, _, pid, reason}, %{ref: ref}) do
    raise "device #{inspect(pid)} exited: " <> Exception.format_exit(reason)
  end

  def handle_info(_, state) do
    {:ok, state}
  end

  def terminate(_reason, state) do
    push_when_exit(state)
    :ok
  end

  # helpers

  defp log_sls_event(level, msg, ts, md, %{metadata: keys} = state) do
    metadata = take_metadata(md, keys)
    timestamp = ts_to_unix(ts)
    level |> build_one_log(msg, timestamp, metadata) |> put_item(state)
    {:ok, state}
  end

  defp ts_to_unix({date, {h, m, s, _}}) do
    {date, {h, m, s}}
    |> :erlang.localtime_to_universaltime()
    |> Timex.to_unix()
  end

  @doc false
  @spec metadata_matches?(Keyword.t(), nil | Keyword.t()) :: true | false
  def metadata_matches?(_md, nil), do: true
  # all of the filter keys are present
  def metadata_matches?(_md, []), do: true

  def metadata_matches?(md, [{key, val} | rest]) do
    case Keyword.fetch(md, key) do
      {:ok, ^val} ->
        metadata_matches?(md, rest)

      # fail on first mismatch
      _ ->
        false
    end
  end

  defp take_metadata(metadata, :all), do: metadata

  defp take_metadata(metadata, keys) do
    metadatas =
      Enum.reduce(keys, [], fn key, acc ->
        case Keyword.fetch(metadata, key) do
          {:ok, val} -> [{key, val} | acc]
          :error -> acc
        end
      end)

    Enum.reverse(metadatas)
  end

  defp configure(name, opts) do
    state = %{
      name: nil,
      level: nil,
      metadata: nil,
      metadata_filter: nil,
      source: nil,
      package_count: nil,
      package_timeout: nil,
      profile: nil,
      logstore: nil
    }

    configure(name, opts, state)
  end

  defp configure(name, opts, state) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, name, opts)

    level = Keyword.get(opts, :level)
    metadata = Keyword.get(opts, :metadata, [])

    metadata =
      case metadata do
        :all ->
          :all

        metadata ->
          (metadata ++ [:duration, :method, :status, :state, :request_path, :params])
          |> Enum.uniq()
      end

    metadata_filter = Keyword.get(opts, :metadata_filter)

    sls_config = Application.get_env(:ex_aliyun_sls, :backend)

    package_count = Keyword.get(sls_config, :package_count, 100)
    package_timeout = Keyword.get(sls_config, :package_timeout)
    logstore = Keyword.get(sls_config, :logstore)

    profile = %{
      endpoint: Keyword.get(sls_config, :endpoint),
      access_key_id: Keyword.get(sls_config, :access_key_id),
      access_key: Keyword.get(sls_config, :access_key),
      project: Keyword.get(sls_config, :project)
    }

    state = %{
      state
      | name: name,
        level: level,
        metadata: metadata,
        metadata_filter: metadata_filter,
        source: get_source(),
        package_count: package_count,
        package_timeout: package_timeout,
        profile: profile,
        logstore: logstore
    }

    case package_timeout do
      nil ->
        :ok

      _timeout ->
        clear_current_package(state)
    end

    state
  end

  def get_source do
    case Node.self() do
      :nonode@nohost ->
        get_inner_ip()

      node_name ->
        node_name |> to_string
    end
  end

  defp get_inner_ip do
    {:ok, [{{p1, p2, p3, p4}, _, _} | _]} = :inet.getif()
    "#{p1}.#{p2}.#{p3}.#{p4}"
  end

  # build log item
  def build_one_log(level, msg, timestamp, metadata) do
    content_list = [level: level] ++ [msg: msg] ++ metadata
    LogRaw.new(Time: timestamp, Contents: build_content(content_list))
  end

  def build_content(kv_list) do
    kv_list
    |> Enum.map(fn {k, v} ->
      LogRaw.Content.new(Key: k |> format, Value: v |> format)
    end)
  end

  def format(item) when is_binary(item) or is_list(item) do
    res = Logger.Formatter.prune(item)

    case is_binary(res) do
      true ->
        res

      false ->
        inspect(res)
    end
  end

  def format(item) when is_atom(item) or is_number(item), do: to_string(item)
  def format(item), do: inspect(item)

  # log package functions
  def put_item(item, %{package_count: package_count} = state) do
    case get_count() < package_count do
      true ->
        add_item_to_package(item)

      false ->
        push_to_sls(state)
        add_item_to_package(item)
    end
  end

  def add_item_to_package(item) do
    Agent.update(
      __MODULE__,
      fn {list, count, pack} -> {[item | list], count + 1, pack} end
    )
  end

  def push_to_sls(state) do
    Agent.update(
      __MODULE__,
      fn {list, _, pack} ->
        Task.start(fn ->
          source = state.source

          Client.post_log_store_logs(%{
            logitems: list |> Enum.reverse(),
            source: source,
            logstore: state.logstore,
            profile: state.profile,
            logtags: [LogTagRaw.new(Key: "__pack_id__", Value: get_pack_id(source, pack))],
            topic: ""
          })
        end)

        {[], 0, pack + 1}
      end
    )
  end

  def get_pack_id(source, pack) do
    context_hash = :crypto.hash(:md5, source) |> Base.encode16() |> String.slice(0..15)
    pack = pack |> to_string
    context_hash <> "-" <> pack
  end

  def clear_current_package(%{package_timeout: package_timeout} = state) do
    case get_count() do
      0 -> "empty"
      _ -> push_to_sls(state)
    end

    Process.send_after(self(), :clear_current_package, package_timeout)
  end

  def push_when_exit(state) do
    {list, _, pack} = Agent.get(__MODULE__, fn package -> package end)
    source = state.source

    Client.post_log_store_logs(%{
      logitems: list |> Enum.reverse(),
      source: source,
      logstore: state.logstore,
      profile: state.profile,
      logtags: [LogTagRaw.new(Key: "__pack_id__", Value: get_pack_id(source, pack))],
      topic: ""
    })
  end

  def get_package do
    Agent.get(__MODULE__, fn {package, _, _} -> package end)
  end

  def get_count do
    Agent.get(__MODULE__, fn {_, count, _} -> count end)
  end

  def empty_package do
    Agent.update(__MODULE__, fn _ -> {[], 0, 0} end)
  end
end
