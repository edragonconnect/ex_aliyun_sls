# ExAliyunSls

## Description
Push your logs to aliyun sls(阿里云日志服务), let your logs be more convenient for statistics.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_aliyun_sls` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_aliyun_sls, "~> 0.1"}
  ]
end
```

## You should log in this way
In elixir, you can log as below.
```elixir
Logger.debug "test1" #1
Logger.info fn -> "test2" end #2
Logger.info fn -> {"test3", [meta1: "meta1", meta2: "meta2", meta3: "meta3"]} end #3
```
In #1, the content will be pushed as `msg`. #2 is same as #1, but it may be better for performance. #3 is the way we encourage, the first element of the tuple will be set as `msg`, the second element - the list is a k-v list, the metadatas can be pushed as a independent field like `meta1`, `meta2`, `meta3`

## Configuration

### Add `YOUR` aliyun sls information into `config/config.exs`

`package_count` means the max logs to push per time, the count will be set default to 100. `package_timeout` means the max time to push logs once, if you want to clear logs by time, you can set it.
```elixir
config :ex_aliyun_sls, :backend,
  endpoint: "YOUR SLS ENDPOINT",
  access_key_id: "YOUR ACCESS KEY ID",
  access_key: "YOUR ACCESS KEY",
  project: "YOUR SLS PROJECT NAME",
  logstore: "YOUR LOG STORE NAME",
  package_count: 100, # Default to 100
  package_timeout: 10_000 # You can choose whether to set it
```

### Config elixir logger

Add ExAliyunSls.LoggerBackend to logger backends, `:sls_log` is just the name of our backend, you can use any atom u like. You can also add other backends to logger.
```elixir
config :logger,
  backends: [
    {ExAliyunSls.LoggerBackend, :sls_log},
  ]
```
Add metadata you may want to push to sls, only the metadata in the list can be handled.
```elixir
config :logger, :sls_log,
  metadata: [:pid, :module, :file, :line, :test_meta]
```
`metadata` can also be set to `:all`, so that all the metadata can be pushed. But in this way `[:pid, :module, :file, :line]` will be pushed by default.

## Change the log format in Plug
Your logs through phoenix endpoint are set default by Plug.Logger. If you want to push it to aliyunsls, you should use our plug instead.

### Replace the plug logger handler
```elixir
# This is the endpoint.ex in your phoenix project

#plug Plug.Logger
plug ExAliyunSls.Plug.Logger
```
With this config, your logs are same as
```elixir
Logger.info fn ->
  {
    "GET: /login, status=200, duration=0.443ms",
    [
      duration: "0.443ms",
      status: 200,
      method: "GET",
      state: "set",
      request_path: "/login",
      params: "{your params will be formatted to json}"
    ]
  }
end
```
Your logs for plug will turn to "GET: /login, Sent 200 in 0.443ms", and it will push the metadatas `duration, method, request_path, status, state, params` to aliyunsls.


### Filter params
If you have some params that should not be logged into logs, you can filter them by setting `filtered_params` in the config file.
```elixir
config :ex_aliyun_sls, :backend,
  endpoint: "YOUR SLS ENDPOINT",
  access_key_id: "YOUR ACCESS KEY ID",
  access_key: "YOUR ACCESS KEY",
  project: "YOUR SLS PROJECT NAME",
  logstore: "YOUR LOG STORE NAME",
  package_count: 100,
  package_timeout: 10_000,
  filtered_params: ["name", "card"] # Add your filtered params here
```
Then your params of http request will filter the `filtered_params`, they will be replaced by `******`.

# Use Embedded Page of Aliyun Sls
To check and search logs in aliyun sls dashboard, we can add an embedded page to our own website.

## Configuration
You should create a role in Aliyun Console to make an `sts` role.
```elixir
    access_key_id: "YOUR SLS ACCESS KEY ID",
    access_key_secret: "YOUR SLS ACCESS KEY SECRET"
```
Attention, the `access_key_id` and `access_key_secret` are not same as your sls account. It is an `Aliyun STS` account. It is used to assume to another Aliyun Role.
```elixir
config :ex_aliyun_sls, :embed_page,
  access_key_id: "YOUR SLS ACCESS KEY ID",
  access_key_secret: "YOUR SLS ACCESS KEY SECRET",
  role_arn: "YOUR ROLE ARN",
  login_page: "YOUR LOGIN PAGE URL",
  destination: "YOUR DESTINATION URL"
```

## How to use it
You can use ExAliyunSls.EmbedPage.get_url/5 to get the embedded page's url.
```elixir
get_url(access_key_id, access_key_secret, role_arn, login_page, destination_page, duration_seconds \\ 3600, role_session_name \\ "default")
```
#### role_arn
`role_arn`: it is Aliyun Resource Name's role, the format is `acs:ram::$accountID:role/$roleName`, such as `acs:ram::1234567890123456:role/samplerole`

#### login_page
`login_page`: it should be the page to redirect to when the embed_page failed.

#### destination_page
`destination_page`: it should be the sls dashboard page you want to add to your page. These types are supported:
`Full log search page`: `https://sls.console.aliyun.com/next/project/<Project名称>/logsearch/<日志库名称>?hideTopbar=true&hideSidebar=true`

`Log search page`: `https://sls.console.aliyun.com/next/project/<Project名称>/logsearch/<日志库名称>?isShare=true&hideTopbar=true&hideSidebar=true`

`Dashboard page`: `https://sls.console.aliyun.com/next/project/<Project名称>/dashboard/<仪表盘名称>?isShare=true&hideTopbar=true&hideSidebar=true`

------

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_aliyun_sls](https://hexdocs.pm/ex_aliyun_sls).
