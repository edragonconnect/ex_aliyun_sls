defmodule ExAliyunSls.EmbedPage do
  @moduledoc """
  Tool for get an Aliyun LogService Dashboard embedded page url.
  """

  alias ExAliyunSls.EmbedPage.Http
  import ExAliyunSls.EmbedPage.Utils

  @signin_host "https://signin.aliyun.com"

  @doc """
  Generate embedded page url.
  """
  def get_url(
        access_key_id,
        access_key_secret,
        role_arn,
        login_page,
        destination_page,
        duration_seconds \\ 3600,
        role_session_name \\ "default"
      ) do
    with {:ok, credentials} <-
           get_sts_token(
             role_arn,
             role_session_name,
             duration_seconds,
             access_key_id,
             access_key_secret
           ),
         {:ok, signin_token} <-
           get_signin_token(
             credentials["AccessKeyId"],
             credentials["AccessKeySecret"],
             credentials["SecurityToken"]
           ) do
      url = get_signin_url(signin_token, login_page, destination_page)
      {:ok, url}
    else
      error -> error
    end
  end

  @doc """
  Get sts token for embedded page.
  """
  def get_sts_token(
        role_arn,
        role_session_name,
        duration_seconds,
        access_key_id,
        access_key_secret
      ) do
    {timestamp, signature_nonce} = get_timestamp()

    common_params = %{
      "Format" => "JSON",
      "RegionId" => "cn-hangzhou",
      "Version" => "2015-04-01",
      "AccessKeyId" => access_key_id,
      "Timestamp" => timestamp,
      "SignatureMethod" => "HMAC-SHA1",
      "SignatureVersion" => "1.0",
      "SignatureNonce" => signature_nonce
    }

    params = %{
      "Action" => "AssumeRole",
      "RoleArn" => role_arn,
      "RoleSessionName" => role_session_name |> format_session_name,
      "DurationSeconds" => duration_seconds
    }

    query = get_query(common_params, params, access_key_secret)

    Http.client(:get_sts_token, query)
    |> Http.post()
  end

  @doc """
  Generate signin token for Aliyun RAM.
  """
  def get_signin_token(access_key_id, access_key_secret, security_token) do
    url = @signin_host <> "/federation"

    params = [
      Action: "GetSigninToken",
      AccessKeyId: access_key_id,
      AccessKeySecret: access_key_secret,
      SecurityToken: security_token
    ]

    Http.client(:get_signin_token)
    |> Http.get(url, query: params)
  end

  def get_signin_url(signin_token, login_page, destination) do
    url = @signin_host <> "/federation"

    params = [
      Action: "Login",
      LoginUrl: login_page,
      Destination: destination,
      SigninToken: signin_token
    ]

    query_string = params |> URI.encode_query()
    url <> "?" <> query_string
  end
end
