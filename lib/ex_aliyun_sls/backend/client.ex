defmodule ExAliyunSls.LoggerBackend.Client do
  @moduledoc """
  Aliyun LogService client to put logs.
  """

  alias ExAliyunSls.LoggerBackend.Http
  alias ExAliyunSls.Log.LogGroupRaw, as: LogGroup

  def post_log_store_logs(%{
        logitems: logitems,
        source: source,
        logstore: logstore,
        profile: profile,
        logtags: logtags,
        topic: topic
      }) do
    log_group =
      LogGroup.new(
        Logs: logitems,
        Source: source,
        LogTags: logtags,
        Topic: topic
      )

    body = LogGroup.encode(log_group)
    resource = "/logstores/" <> logstore <> "/shards/lb"
    content_type = "application/x-protobuf"
    request_api("POST", :post_log_store_logs, body, resource, content_type, profile)
  end

  def request_api(method, api, body, resource, content_type, profile) do
    host = profile.project <> "." <> profile.endpoint
    date = Timex.now() |> Timex.format!("%a, %d %b %Y %H:%M:%S GMT", :strftime)
    body_length = body |> byte_size |> to_string
    md5 = :crypto.hash(:md5, body) |> Base.encode16(case: :upper)
    version = "0.6.0"
    sign_method = "hmac-sha1"

    canonicalized_log_headers =
      "x-log-apiversion:#{version}\nx-log-bodyrawsize:#{body_length}\nx-log-signaturemethod:#{
        sign_method
      }"

    content =
      "#{method}\n#{md5}\n#{content_type}\n#{date}\n#{canonicalized_log_headers}\n#{resource}"

    signature = :crypto.hmac(:sha, profile.access_key, content) |> Base.encode64()
    authorization = "LOG " <> profile.access_key_id <> ":" <> signature

    headers = [
      {"Content-Length", body_length},
      {"Content-MD5", md5},
      {"content-type", content_type},
      {"x-log-bodyrawsize", body_length},
      {"x-log-apiversion", version},
      {"x-log-signaturemethod", sign_method},
      {"Host", host},
      {"Date", date},
      {"Authorization", authorization}
    ]

    url = "http://#{profile.project}.#{profile.endpoint}#{resource}"

    case method do
      "POST" ->
        api
        |> Http.client(url, body, headers)
        |> Http.post()

      "GET" ->
        "TODO"

      method ->
        method
    end
  end
end
