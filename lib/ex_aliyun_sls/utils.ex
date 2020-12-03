defmodule ExAliyunSls.Utils do
  @moduledoc false

  def get_source do
    case Node.self() do
      :nonode@nohost -> get_inner_ip()
      node_name -> node_name |> to_string
    end
  end

  defp get_inner_ip do
    {:ok, [{{p1, p2, p3, p4}, _, _} | _]} = :inet.getif()
    "#{p1}.#{p2}.#{p3}.#{p4}"
  end

  def get_profile(log_store_key \\ :logstore) do
    sls_config = Application.get_env(:ex_aliyun_sls, :backend)
    log_store = Keyword.get(sls_config, log_store_key)
    project = Keyword.get(sls_config, :project)
    endpoint = Keyword.get(sls_config, :endpoint)

    %{
      log_store: log_store,
      resource: "/logstores/" <> log_store <> "/shards/lb",
      project: project,
      endpoint: endpoint,
      access_key_id: Keyword.get(sls_config, :access_key_id),
      access_key: Keyword.get(sls_config, :access_key),
      host: project <> "." <> endpoint
    }
  end
end
