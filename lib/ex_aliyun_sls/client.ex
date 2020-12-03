defmodule ExAliyunSls.Client do
  @moduledoc """
  Aliyun LogService client
  """
  use Tesla
  alias ExAliyunSls.LogGroup

  adapter({Tesla.Adapter.Finch, [name: ExAliyunSls.Finch]})
  plug(Tesla.Middleware.Timeout, timeout: 5_000)
  plug(Tesla.Middleware.Retry, delay: 5_000, max_retries: 5)

  def push2log_store(log_items, log_tags, topic, source, profile) do
    LogGroup.new(Logs: log_items, Source: source, LogTags: log_tags, Topic: topic)
    |> LogGroup.encode()
    |> request_api(profile)
  end

  def request_api(body, profile) do
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
      "POST\n#{md5}\napplication/x-protobuf\n#{date}\n#{canonicalized_log_headers}\n#{profile.resource}"

    signature = :crypto.hmac(:sha, profile.access_key, content) |> Base.encode64()
    authorization = "LOG " <> profile.access_key_id <> ":" <> signature

    headers = [
      {"Content-Length", body_length},
      {"Content-MD5", md5},
      {"content-type", "application/x-protobuf"},
      {"x-log-bodyrawsize", body_length},
      {"x-log-apiversion", version},
      {"x-log-signaturemethod", sign_method},
      {"Host", host},
      {"Date", date},
      {"Authorization", authorization}
    ]

    case post("http://#{host}#{profile.resource}", body, headers: headers) do
      {:ok, %Tesla.Env{status: 200}} ->
        {:ok, "success"}

      {:ok, %Tesla.Env{status: code, body: body}} ->
        {:error, "error_code: #{code}, msg: #{body}"}

      error ->
        error
    end
  end
end