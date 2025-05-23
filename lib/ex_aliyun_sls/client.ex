defmodule ExAliyunSls.Client do
  @moduledoc """
  Aliyun LogService client
  """
  use Tesla
  alias ExAliyunSls.LogGroup

  @version "0.6.0"
  @sign_method "hmac-sha1"
  @content_type "application/x-protobuf"

  adapter({Tesla.Adapter.Finch, [name: ExAliyunSls.Finch]})
  plug(Tesla.Middleware.Timeout, timeout: 5_000)
  plug(Tesla.Middleware.Retry, delay: 5_000, max_retries: 5)

  def push2log_store(log_items, log_tags, topic, source, profile) do
    log_group = %LogGroup{
      Logs: log_items,
      Source: source,
      LogTags: log_tags,
      Topic: topic
    }
    {iodata, size} = LogGroup.encode!(log_group)
    iodata |> request_api(size, profile)
  end

  defp request_api(body, body_length, profile) do
    host = profile.host
    date = Calendar.strftime(DateTime.now!("Etc/UTC"), "%a, %d %b %Y %H:%M:%S GMT")
    body_length = to_string(body_length)
    md5 = :md5 |> :crypto.hash(body) |> Base.encode16(case: :upper)

    canonicalized_log_headers =
      "x-log-apiversion:#{@version}\nx-log-bodyrawsize:#{body_length}\nx-log-signaturemethod:#{@sign_method}"

    content =
      "POST\n#{md5}\n#{@content_type}\n#{date}\n#{canonicalized_log_headers}\n#{profile.resource}"

    signature =
      ExAliyunSls.Utils.crypto_hmac(:sha, profile.access_key, content) |> Base.encode64()

    authorization = "LOG " <> profile.access_key_id <> ":" <> signature

    headers = [
      {"Content-Length", body_length},
      {"Content-MD5", md5},
      {"content-type", @content_type},
      {"x-log-bodyrawsize", body_length},
      {"x-log-apiversion", @version},
      {"x-log-signaturemethod", @sign_method},
      {"Host", host},
      {"Date", date},
      {"Authorization", authorization}
    ]

    case post("#{profile.scheme}://#{host}#{profile.resource}", body, headers: headers) do
      {:ok, %Tesla.Env{status: 200}} ->
        {:ok, "success"}

      {:ok, %Tesla.Env{status: code, body: body}} ->
        {:error, "error_code: #{code}, msg: #{body}"}

      error ->
        error
    end
  end
end
