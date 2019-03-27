defmodule EmbeddedPageTest do
  use ExUnit.Case, async: false

  test "get sts token" do
    config = Application.get_env(:ex_aliyun_sls, :embed_page)

    assert {:ok, _} =
             ExAliyunSls.EmbedPage.get_sts_token(
               config |> Keyword.get(:role_arn),
               "default",
               3600,
               config |> Keyword.get(:access_key_id),
               config |> Keyword.get(:access_key_secret)
             )
  end

  test "get signin token" do
    config = Application.get_env(:ex_aliyun_sls, :embed_page)

    assert {:ok, credentials} =
             ExAliyunSls.EmbedPage.get_sts_token(
               config |> Keyword.get(:role_arn),
               "default",
               3600,
               config |> Keyword.get(:access_key_id),
               config |> Keyword.get(:access_key_secret)
             )

    assert {:ok, signin_token} =
             ExAliyunSls.EmbedPage.get_signin_token(
               credentials["AccessKeyId"],
               credentials["AccessKeySecret"],
               credentials["SecurityToken"]
             )
  end
end
