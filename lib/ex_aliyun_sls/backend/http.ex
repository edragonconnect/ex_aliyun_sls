defmodule ExAliyunSls.LoggerBackend.PutLogsMiddleware do
  @moduledoc false

  @behaviour Tesla.Middleware

  def call(env, next, opts) do
    url = Keyword.get(opts, :url)
    body = Keyword.get(opts, :body)
    headers = Keyword.get(opts, :headers)

    env
    |> prepare_request(url, body, headers)
    |> Tesla.run(next)
    |> decode_response()
  end

  defp prepare_request(env, url, body, headers) do
    env
    |> Tesla.put_headers(headers)
    |> Tesla.put_body(body)
    |> Map.put(:url, url)
  end

  defp decode_response(env) do
    case env do
      {:ok, %Tesla.Env{status: 200}} ->
        {:ok, "success"}

      {:ok, %Tesla.Env{status: code, body: body}} ->
        {:error, "error_code: #{code}, msg: #{body}"}

      error ->
        error
    end
  end
end

defmodule ExAliyunSls.LoggerBackend.Http do
  @moduledoc false

  use Tesla
  adapter(Tesla.Adapter.Hackney)

  plug(Tesla.Middleware.Timeout, timeout: 5_000)
  plug(Tesla.Middleware.Retry, delay: 5_000, max_retries: 5)

  def client(:post_log_store_logs, url, body, headers) do
    Tesla.client([
      {ExAliyunSls.LoggerBackend.PutLogsMiddleware, url: url, body: body, headers: headers}
    ])
  end

  def post(client) do
    post(client, "/", nil)
  end
end
