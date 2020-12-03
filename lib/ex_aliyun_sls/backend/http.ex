defmodule ExAliyunSls.LoggerBackend.Http do
  @moduledoc """
  Tesla client for sls logger backend.
  """

  use Tesla

  adapter({Tesla.Adapter.Finch, [name: ExAliyunSls.Finch]})
  plug(Tesla.Middleware.Timeout, timeout: 5_000)
  plug(Tesla.Middleware.Retry, delay: 5_000, max_retries: 5)

  def send_post(url, body, options) do
    case post(url, body, options) do
      {:ok, %Tesla.Env{status: 200}} ->
        {:ok, "success"}

      {:ok, %Tesla.Env{status: code, body: body}} ->
        {:error, "error_code: #{code}, msg: #{body}"}

      error ->
        error
    end
  end
end
