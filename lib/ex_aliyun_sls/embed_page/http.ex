defmodule ExAliyunSls.EmbedPage.StsMiddleware do
  @moduledoc false

  @behaviour Tesla.Middleware

  def call(env, next, opts) do
    query = Keyword.get(opts, :params)

    env
    |> prepare_request(query)
    |> Tesla.run(next)
    |> decode_response()
  end

  defp prepare_request(env, query) do
    env
    |> Map.put(:query, query)
    |> Map.put(:url, "https://sts.aliyuncs.com")
  end

  defp decode_response(env) do
    case env do
      {:ok, %Tesla.Env{status: 200} = resp} ->
        body = resp.body |> Jason.decode!()
        {:ok, body["Credentials"]}

      {:ok, %Tesla.Env{status: code, body: body}} ->
        {:error, "error_code: #{code}, msg: #{body}"}

      error ->
        error
    end
  end
end

defmodule ExAliyunSls.EmbedPage.SigninMiddleware do
  @moduledoc false

  @behaviour Tesla.Middleware

  def call(env, next, _opts) do
    env
    |> Tesla.run(next)
    |> decode_response()
  end

  defp decode_response(env) do
    case env do
      {:ok, %Tesla.Env{status: 200} = resp} ->
        body = resp.body |> Jason.decode!()
        {:ok, body["SigninToken"]}

      {:ok, %Tesla.Env{status: code, body: body}} ->
        {:error, "error_code: #{code}, msg: #{body}"}

      error ->
        error
    end
  end
end

defmodule ExAliyunSls.EmbedPage.Http do
  @moduledoc false

  use Tesla

  # plug(Tesla.Middleware.Timeout, timeout: 5_000)
  # plug(Tesla.Middleware.Retry, delay: 5_000, max_retries: 5)

  def client(:get_sts_token, params) do
    Tesla.client([
      {ExAliyunSls.EmbedPage.StsMiddleware, params: params}
    ])
  end

  def client(:get_signin_token) do
    Tesla.client([
      {ExAliyunSls.EmbedPage.SigninMiddleware, []}
    ])
  end

  def post(client) do
    post(client, "/", [])
  end
end
