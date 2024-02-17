defmodule Merquery.Helpers.Constants do
  @moduledoc false

  @allowed_verbs [:get, :post, :put, :patch, :delete, :head, :options]

  @req_args [
    :method,
    :url,
    :headers,
    :body,
    :adapter
  ]

  @req_opts [
    # request steps
    :user_agent,
    :compressed,
    :range,
    :base_url,
    :params,
    :path_params,
    :auth,
    :form,
    :json,
    :compress_body,
    :checksum,
    :aws_sigv4,

    # response steps
    :raw,
    :http_errors,
    :decode_body,
    :decode_json,
    :redirect,
    :redirect_trusted,
    :redirect_log_level,
    :max_redirects,
    :retry,
    :retry_delay,
    :retry_log_level,
    :max_retries,
    :cache,
    :cache_dir,
    :plug,
    :finch,
    :finch_request,
    :finch_private,
    :connect_options,
    :inet6,
    :receive_timeout,
    :pool_timeout,
    :unix_socket,
    :redact_auth,

    # TODO: Remove on Req 1.0
    :output,
    :follow_redirects,
    :location_trusted
  ]

  @merquery_opts [
    :preview_body
  ]

  defguard is_req_opt(v) when v in @req_opts
  defguard is_req_arg(v) when v in @req_args
  defguard is_merquery_opt(v) when v in @merquery_opts
  def all_verb_strings(), do: Enum.map(@allowed_verbs, &Atom.to_string/1)
  def all_verbs(), do: @allowed_verbs
end
