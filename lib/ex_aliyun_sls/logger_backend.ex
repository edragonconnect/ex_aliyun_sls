defmodule ExAliyunSls.LoggerBackend do
  @moduledoc """
  The logger backend to send your logs to Aliyun Log Service by package.
  """

  @behaviour :gen_event

  @type level :: Logger.level()
  @type metadata :: [atom]

  alias ExAliyunSls.{Log, LogTag, Client, Utils}

  def init({__MODULE__, name}) do
    Process.flag(:trap_exit, true)

    Agent.start_link(fn -> {[], 0, 0} end, name: __MODULE__)
    state = configure(name, [])

    if is_integer(state.package_timeout) do
      Process.send_after(self(), :clear_current_package, state.package_timeout)
    end

    {:ok, state}
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
    flush2sls(state)
    Process.send_after(self(), :clear_current_package, state.package_timeout)
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
    {utc_date, utc_time} = :erlang.localtime_to_universaltime({date, {h, m, s}})
    utc_date
    |> Date.from_erl!()
    |> DateTime.new!(Time.from_erl!(utc_time))
    |> DateTime.to_unix()
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
    Enum.reduce(keys, [], fn key, acc ->
      case Keyword.fetch(metadata, key) do
        {:ok, val} -> [{key, val} | acc]
        :error -> acc
      end
    end)
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
      profile: nil
    }

    configure(name, opts, state)
  end

  defp configure(name, opts, state) do
    env = Application.get_env(:logger, name, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, name, opts)

    level = Keyword.get(opts, :level)
    metadata_filter = Keyword.get(opts, :metadata_filter)

    metadata =
      case Keyword.get(opts, :metadata, []) do
        :all ->
          :all

        metadata ->
          Enum.uniq([:duration, :method, :status, :state, :request_path, :params | metadata])
      end

    sls_config = Application.get_env(:ex_aliyun_sls, :backend)
    package_count = Keyword.get(sls_config, :package_count, 100) - 1
    package_timeout = Keyword.get(sls_config, :package_timeout)
    profile = Utils.get_profile()

    %{
      state
      | name: name,
        level: level,
        metadata: metadata,
        metadata_filter: metadata_filter,
        source: Utils.get_source(),
        package_count: package_count,
        package_timeout: package_timeout,
        profile: profile
    }
  end

  # build log item
  def build_one_log(level, msg, timestamp, metadata) do
    msg = msg |> Logger.Formatter.prune() |> to_string()

    contents =
      metadata
      |> Enum.reduce(
        [
          %Log.Content{Key: "level", Value: Atom.to_string(level)},
          %Log.Content{Key: "msg", Value: msg}
        ],
        fn {k, v}, acc ->
          if formatted = metadata(k, v) do
            [%Log.Content{Key: Atom.to_string(k), Value: formatted} | acc]
          else
            acc
          end
        end
      )

    %Log{Time: timestamp, Contents: contents}
  end

  # log package functions
  def put_item(item, %{package_count: package_count} = state) do
    Agent.update(
      __MODULE__,
      fn
        {list, count, pack_id} when count < package_count ->
          {[item | list], count + 1, pack_id}

        {list, _count, pack_id} ->
          send_logs(state, [item | list], pack_id)
          {[], 0, pack_id + 1}
      end
    )
  end

  def get_pack_id(source, pack) do
    context_hash = :crypto.hash(:md5, source) |> Base.encode16() |> String.slice(0..15)
    pack = pack |> to_string
    context_hash <> "-" <> pack
  end

  def flush2sls(state) do
    Agent.update(
      __MODULE__,
      fn
        {[], _, pack_id} ->
          {[], 0, pack_id}

        {list, _, pack_id} ->
          send_logs(state, list, pack_id)
          {[], 0, pack_id + 1}
      end
    )
  end

  defp push_when_exit(state) do
    case Agent.get(__MODULE__, & &1) do
      {[], _, _} ->
        :skip

      {list, _, pack} ->
        source = state.source
        log_tags = [%LogTag{Key: "__pack_id__", Value: get_pack_id(source, pack)}]
        Client.push2log_store(Enum.reverse(list), log_tags, "", source, state.profile)
    end
  end

  def get_package, do: Agent.get(__MODULE__, &elem(&1, 0))
  def get_count, do: Agent.get(__MODULE__, &elem(&1, 1))

  def empty_package do
    Agent.update(__MODULE__, fn _ -> {[], 0, 0} end)
  end

  defp send_logs(state, log_items, pack_id) do
    Task.start(fn ->
      source = state.source
      log_tags = [%LogTag{Key: "__pack_id__", Value: get_pack_id(source, pack_id)}]
      Client.push2log_store(Enum.reverse(log_items), log_tags, "", source, state.profile)
    end)
  end

  defp metadata(_, nil), do: nil
  defp metadata(_, string) when is_binary(string), do: string
  defp metadata(_, integer) when is_integer(integer), do: Integer.to_string(integer)
  defp metadata(_, float) when is_float(float), do: Float.to_string(float)
  defp metadata(_, pid) when is_pid(pid), do: pid |> :erlang.pid_to_list() |> to_string()

  defp metadata(_, atom) when is_atom(atom) do
    case Atom.to_string(atom) do
      "Elixir." <> rest -> rest
      "nil" -> ""
      binary -> binary
    end
  end

  defp metadata(_, ref) when is_reference(ref) do
    ~c"#Ref" ++ rest = :erlang.ref_to_list(ref)
    to_string(rest)
  end

  defp metadata(:params, params) when is_list(params), do: inspect(params)
  defp metadata(:file, file) when is_list(file), do: to_string(file)
  defp metadata(_, list) when is_list(list), do: list |> Logger.Formatter.prune() |> to_string()

  defp metadata(:domain, [head | tail]) when is_atom(head) do
    Enum.map_intersperse([head | tail], ?., &Atom.to_string/1)
  end

  defp metadata(:mfa, {mod, fun, arity})
       when is_atom(mod) and is_atom(fun) and is_integer(arity) do
    Exception.format_mfa(mod, fun, arity)
  end

  defp metadata(:initial_call, {mod, fun, arity})
       when is_atom(mod) and is_atom(fun) and is_integer(arity) do
    Exception.format_mfa(mod, fun, arity)
  end

  defp metadata(_, value), do: inspect(value)
end
