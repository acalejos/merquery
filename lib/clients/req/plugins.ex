defmodule Merquery.Clients.Req.Plugins do
  @moduledoc false

  def plugins do
    [
      %{
        "name" => "req_easyhtml",
        "description" => "Req plugin for EasyHTML",
        "version" => ~s({:req_easyhtml, ~> "0.1.0"}),
        "active" => false
      },
      %{
        "name" => "req_s3",
        "version" => ~s({:req_s3, ~> "0.1.0"}),
        "description" => "Req plugin for Amazon S3.",
        "active" => false
      },
      %{
        "name" => "req_hex",
        "version" => ~s({:req_hex, ~> "0.1.0"}),
        "description" => "Req plugin for Hex API.",
        "active" => false
      },
      %{
        "name" => "req_github_oauth",
        "description" => "Req plugin for GitHub authentication.",
        "version" => ~s({:req_github_oauth, ~> "0.1.0"}),
        "active" => false
      },
      %{
        "name" => "req_github_paginate",
        "version" => ~s({:req_github_paginate, github: "acalejos/req_github_paginate"}),
        "description" => "Parses GitHub's REST Response Link Headers",
        "active" => false
      }
    ]
  end

  def plugin_to_module(%{"name" => "req_easyhtml"}), do: ReqEasyHTML
  def plugin_to_module(%{"name" => "req_s3"}), do: ReqS3
  def plugin_to_module(%{"name" => "req_hex"}), do: ReqHex
  def plugin_to_module(%{"name" => "req_github_oauth"}), do: ReqGitHubOAuth
  def plugin_to_module(%{"name" => "req_github_paginate"}), do: ReqGitHubPaginate
end
