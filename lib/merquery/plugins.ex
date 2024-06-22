defmodule Merquery.Plugins do
  alias Merquery.Schemas.Plugin
  @moduledoc false

  def loaded_plugins do
    # This accounts for functions defined during runtime or in the Livebook
    all_loaded =
      for {mod, _} <- :code.all_loaded(),
          mod != Req.Steps,
          function_exported?(Code.ensure_loaded!(mod), :attach, 1) do
        mod
      end

    attach_exported? = fn mod ->
      case Code.ensure_loaded(mod) do
        {:error, :nofile} ->
          false

        {:module, module} ->
          function_exported?(module, :attach, 1)
      end
    end

    # This is mainly used to account for dependencies without having to
    # load all modules
    app_mods =
      for {mod, _, _} <- Application.loaded_applications(),
          {:ok, modules} = :application.get_key(mod, :modules),
          mod <- modules,
          mod != Req.Steps,
          attach_exported?.(mod) do
        mod
      end

    for mod <- MapSet.new(all_loaded ++ app_mods),
        reduce: [] do
      acc ->
        case Code.fetch_docs(mod) do
          {:docs_v1, _, :elixir, _, %{"en" => module_doc}, _, _} ->
            mod = mod |> Module.split() |> Enum.join(".")
            doc = module_doc |> String.split("\n") |> Enum.at(0)
            [%{name: mod, description: doc, active: false} | acc]

          {:docs_v1, _, :elixir, _, :none, _, _} ->
            mod = mod |> Module.split() |> Enum.join(".")
            [%{name: mod, description: "", active: false} | acc]

          {_, _, :erlang, _, _, _, _} ->
            acc

          {:error, :module_not_found} ->
            acc

          {:error, :chunk_not_found} ->
            acc
        end
    end
  end

  def available_plugins do
    [
      %{
        name: "ReqEasyHTML",
        description: "Req plugin for EasyHTML",
        version: ~s({:req_easyhtml, "~> 0.1.0"})
      },
      %{
        name: "ReqS3",
        version: ~s({:req_s3, "~> 0.1.0"}),
        description: "Req plugin for Amazon S3."
      },
      %{
        name: "ReqHex",
        version: ~s({:req_hex, "~> 0.1.0"}),
        description: "Req plugin for Hex API."
      },
      %{
        name: "ReqGitHubOAuth",
        description: "Req plugin for GitHub authentication.",
        version: ~s({:req_github_oauth, "~> 0.1.0"})
      },
      %{
        name: "ReqGitHubPaginate",
        version: ~s({:req_github_paginate, github: "acalejos/req_github_paginate"}),
        description: "Parses GitHub's REST Response Link Headers"
      },
      %{
        name: "ReqTelemetry",
        version: ~s({:req_telemetry, "~> 0.0.4"}),
        description: "Req plugin to instrument requests with Telemetry events"
      },
      %{
        name: "ReqFuse",
        version: ~s({:req_fuse, "~> 0.2.3"}),
        description:
          "ReqFuse provides circuit-breaking functionality, using fuse, for HTTP requests that use Req. Req: https://github.com/wojtekmach/req Fuse: ttps://github.com/jlouis/fuse"
      },
      %{
        name: "ReqBigQuery",
        version: ~s({:req_bigquery, "~> 0.1.3"}),
        description: "Req plugin for Google BigQuery"
      },
      %{
        name: "ReqAthena",
        version: ~s({:req_athena, "~> 0.1.5"}),
        description: "Req plugin for AWS Athena"
      },
      %{
        name: "ReqSandbox",
        version: ~s({:req_sandbox, "~> 0.1.2"}),
        description: "ReqSandbox simplifies concurrent, transactional tests for external clients."
      },
      %{
        name: "ReqSnowflake",
        version: ~s({:req_snowflake, github: "joshuataylor/req_snowflake"}),
        description: "An Elixir driver for Snowflake, the cloud data platform."
      },
      %{
        name: "ReqCrawl",
        version: ~s({:req_crawl, "~> 0.2.0"}),
        description: "Req plugins to support common crawling functions."
      }
    ]
    |> Enum.map(&Plugin.new/1)
    |> Enum.sort_by(&Map.fetch!(&1, :name))
  end
end
