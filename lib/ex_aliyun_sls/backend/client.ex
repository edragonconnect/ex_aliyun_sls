defmodule ExAliyunSls.LoggerBackend.Client do
  @moduledoc """
  Aliyun LogService client to put logs.
  """

  alias ExAliyunSls.LoggerBackend.Http
  alias ExAliyunSls.LogGroup

  def post_log_store_logs(%{
        logitems: logitems,
        source: source,
        logstore: logstore,
        profile: profile,
        logtags: logtags,
        topic: topic
      }) do
    body =
      LogGroup.new(Logs: logitems, Source: source, LogTags: logtags, Topic: topic)
      |> LogGroup.encode()

    resource = "/logstores/" <> logstore <> "/shards/lb"
    content_type = "application/x-protobuf"
    request_api("POST", body, resource, content_type, profile)
  end

  def request_api(method, body, resource, content_type, profile) do
    host = profile.host
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

    Http.send_post("http://#{host}#{resource}", body, headers: headers)
  end
end
