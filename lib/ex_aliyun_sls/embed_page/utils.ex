defmodule ExAliyunSls.EmbedPage.Utils do
  @moduledoc """
  Utils for generating embedded page.
  """

  def get_timestamp do
    now = Timex.now()
    timestamp = now |> Timex.format!("%Y-%m-%dT%H:%M:%SZ", :strftime)
    signature_nonce = UUID.uuid1()
    {timestamp, signature_nonce}
  end

  def get_query(common_params, params, access_key_secret) do
    sign_params = common_params |> Map.merge(params)
    string_to_sign = sign_params |> format_string_to_sign() |> String.replace("%2B", "%2520")
    signature = sign(access_key_secret, string_to_sign)

    sign_params
    |> Map.put("Signature", signature)
    |> to_keyword_list
  end

  def format_string_to_sign(params) do
    format_string =
      params
      |> Map.keys()
      |> Enum.sort()
      |> Enum.map(fn key ->
        "#{URI.encode_www_form(key)}=#{URI.encode_www_form(to_string(params[key]))}"
      end)
      |> Enum.join("&")
      |> URI.encode_www_form()

    "POST&%2F&" <> format_string
  end

  def sign(access_key_secret, string_to_sign) do
    access_key_secret = access_key_secret <> "&"

    ExAliyunSls.Utils.crypto_hmac(:sha, access_key_secret, string_to_sign)
    |> Base.encode64()
  end

  def to_keyword_list(map) do
    map
    |> Enum.map(fn {k, v} ->
      {String.to_atom(k), v}
    end)
  end

  def format_session_name(role_session_name) do
    role_session_name
    |> String.replace(" ", "_")
  end
end
