# ExAliyunSls

[![Module Version](https://img.shields.io/hexpm/v/ex_aliyun_sls.svg)](https://hex.pm/packages/ex_aliyun_sls)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/ex_aliyun_sls/)
[![Total Download](https://img.shields.io/hexpm/dt/ex_aliyun_sls.svg)](https://hex.pm/packages/ex_aliyun_sls)
[![License](https://img.shields.io/hexpm/l/ex_aliyun_sls.svg)](https://github.com/edragonconnect/ex_aliyun_sls/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/edragonconnect/ex_aliyun_sls.svg)](https://github.com/edragonconnect/ex_aliyun_sls/commits/master)

## Description

`ExAliyunSls` is an Elixir SDK client for Aliyun SLS (阿里云日志服务). It allows you to push your logs to Aliyun Log Service, making them more convenient for statistics, visualization, and analysis.

## Features

- Logger backend for sending logs to Aliyun SLS
- Custom Plug for Phoenix applications
- Parameter filtering for sensitive data
- Embedded page integration for viewing logs in your application
- Batched log sending with configurable package size and timeout

## Installation

The package can be installed by adding `:ex_aliyun_sls` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_aliyun_sls, "~> 0.4"}
  ]
end
```

## Logging Methods

In Elixir, you can log in the following ways:

```elixir
Logger.debug "test1" #1
Logger.info fn -> "test2" end #2
Logger.info fn -> {"test3", [meta1: "meta1", meta2: "meta2", meta3: "meta3"]} end #3
```

- Example #1 is the log content will be pushed as `msg` in `debug` level.
- Example #2 is the simliar as #1, but it may be better for performance as the string is only evaluated if the log level is enabled.
- Example #3 is the recommended approach, the first element of the tuple will be set as `msg`, and the second element (the keyword list) contains metadata that will be pushed as independent fields like `meta1`, `meta2`, `meta3`.

## Configuration

### Aliyun SLS Configuration

Add your Aliyun SLS information to config/config.exs with the following options:

```elixir
config :ex_aliyun_sls, :backend,
  endpoint: "YOUR SLS ENDPOINT",
  access_key_id: "YOUR ACCESS KEY ID",
  access_key: "YOUR ACCESS KEY",
  project: "YOUR SLS PROJECT NAME",
  logstore: "YOUR LOG STORE NAME",
  package_count: 100, # Default to 100
  package_timeout: 10_000, # Optional, Default to nil
  http_protocol: "https", # Default to "https"
  filtered_params: ["password", "token"] # Optional, for filtering sensitive data
```

Configuration Options:

- `endpoint`: The Aliyun SLS service endpoint (required)
- `access_key_id`: Your Aliyun RAM user access key ID (required)
- `access_key`: Your Aliyun RAM user access key secret (required)
- `project`: Your SLS project name (required)
- `logstore`: Your SLS logstore name (required)
- `package_count`: Maximum number of logs to push per batch, default is 100
- `package_timeout`: Maximum time (in milliseconds) to wait before pushing logs, default is `nil` when using `ExAliyunSls.LoggerBackend`, set this if you want to clear logs regularly.
- `http_protocol`: The HTTP protocol for requests to Aliyun Cloud Server, default is "https"
- `filtered_params`: List of parameter names that should be filtered from logs for privacy/security

Please ensure the `access_key_id` and `access_key` are correct and have the necessary permissions to write to your SLS project.

### Logger Configuration

```elixir
config :logger,
  backends: [
    {ExAliyunSls.LoggerBackend, :sls_log},
  ]
```

The atom `:sls_log` is just an identifier for the backend - you can use any atom you prefer. You can also add other logger backends alongside this one.

Configure which metadata to include in your logs:

```elixir
config :logger, :sls_log,
  level: :info, # Optional, sets minimum log level
  metadata: [:pid, :module, :file, :line, :function, :application]
```

Metadata Options:

- Set `metadata` to `:all` to include all available metadata in your logs
- Set `metadata` to a list of specific metadata keys you want to include
- When using the Phoenix integration, the following metadata is automatically included: `[:duration, :method, :status, :state, :request_path, :params]`
- Default metadata when using `:all` includes `[:pid, :module, :file, :line]`

### Log Level Filtering

You can set a minimum log level for the SLS backend:
```elixir
config :logger, :sls_log,
  level: :info
```
This will only log messages with a level of `:info` or higher.

## Phoenix Integration

Your logs through Phoenix endpoint are set by default by Plug.Logger . If you want to push them to Aliyun SLS, you should use our plug instead.

### Replace the Plug Logger Handler

```elixir
# This is the endpoint.ex in your phoenix project
# plug Plug.Logger
plug ExAliyunSls.Plug.Logger
```

With this configuration, your logs will be formatted as:

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

Your logs for plug will appear as "GET: /login, Sent 200 in 0.443ms", and it will push the metadata `duration`, `method`, `request_path`, `status`, `state`, and `params` to Aliyun SLS.

### Filter Sensitive Parameters

If you have parameters that should not be logged, you can filter them by setting `filtered_params` in the config file:

```elixir
config :ex_aliyun_sls, :backend,
  endpoint: "YOUR SLS ENDPOINT",
  access_key_id: "YOUR ACCESS KEY ID",
  access_key: "YOUR ACCESS KEY",
  project: "YOUR SLS PROJECT NAME",
  logstore: "YOUR LOG STORE NAME",
  package_count: 100,
  package_timeout: 10_000,
  filtered_params: ["password", "token", "credit_card", "secret"] # Add your filtered params here
```

Filtered parameters in HTTP requests will be replaced with "******" in the logs.

## Embedded Page Integration

To check and search logs in the Aliyun SLS dashboard, you can add an embedded page to your own website.

### Configuration

Create a role in the Aliyun RAM Access Control Console, set the proper attributes of the role and related permissions.

```elixir
config :ex_aliyun_sls, :embed_page,
  access_key_id: "YOUR SLS ACCESS KEY ID",
  access_key_secret: "YOUR SLS ACCESS KEY SECRET",
  role_arn: "YOUR ROLE ARN",
  login_page: "YOUR LOGIN PAGE URL",
  destination: "YOUR DESTINATION URL"
```

Important: The above `access_key_id` and `access_key_secret` still come from the RAM user, which can be given specialized permissions to assume roles via the `AliyunSTSAssumeRoleAccess` authorization policy.

### How to Use It

You can use `ExAliyunSls.EmbedPage.get_url/7` to get the embedded page's URL:

```elixir
get_url(access_key_id, access_key_secret, role_arn, login_page, destination_page, duration_seconds \\ 3600, role_session_name \\ "default")
```

- `role_arn`: It is created in the Aliyun RAM Access Control Console - Role section, the format is `acs:ram::$accountID:role/$roleName`, such as `acs:ram::1234567890123456:role/samplerole`.
- `login_page`: The page to redirect to when the embedded page fails to load.
- `destination_page`: The SLS dashboard page you want to add to your page, these types are supported:
  - Full log search page : `https://sls.console.aliyun.com/next/project/<Project名称>/logsearch/<日志库名称>?hideTopbar=true&hideSidebar=true`
  - Log search page : `https://sls.console.aliyun.com/next/project/<Project名称>/logsearch/<日志库名称>?isShare=true&hideTopbar=true&hideSidebar=true`
  - Dashboard page : `https://sls.console.aliyun.com/next/project/<Project名称>/dashboard/<仪表盘名称>?isShare=true&hideTopbar=true&hideSidebar=true`

### Example Implementation

```elixir
def get_embedded_dashboard_url do
  config = Application.get_env(:ex_aliyun_sls, :embed_page)
  
  {:ok, url} = ExAliyunSls.EmbedPage.get_url(
    config[:access_key_id],
    config[:access_key_secret],
    config[:role_arn],
    config[:login_page],
    config[:destination]
  )
  
  url
end
```

## Advanced Usage

### Batch Log Processing

The SDK automatically batches logs based on the `package_count` and `package_timeout` settings:

- When the number of logs reaches `package_count`, they are automatically sent to Aliyun SLS
- If `package_timeout` is set, logs will be sent after that duration even if the count hasn't been reached
- Logs are also flushed when the application terminates

This approach optimizes network usage while ensuring logs are delivered in a timely manner.

## Local Development

Use the following configuration to run the tests:

```elixir
import Config

config :logger,
  backends: [
    {ExAliyunSls.LoggerBackend, :sls},
  ]
  
config :ex_aliyun_sls, :backend,
  endpoint: "...",
  access_key_id: "..."
  access_key: "..."
  project: "...",
  logstore: "...",
  package_count: 10,
  package_timeout: 5_000

config :ex_aliyun_sls, :embed_page,
  endpoint: "...",
  access_key_id: "...",
  access_key_secret: "...",
  role_arn: "..."
```

## Copyright and License

Copyright (c) 2019 eDragonConnect

This work is free. You can redistribute it and/or modify it under the
terms of the MIT License. See the [LICENSE.md](./LICENSE.md) file for more details.
