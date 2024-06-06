defmodule Merquery.SmartCell do
  use Kino.JS, assets_path: "assets/build"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Merquery"
  alias Merquery.Helpers.Constants

  defp get_default_steps() do
    {:docs_v1, _annotation, _beam_language, _format, _module_doc, _metadata, docs} =
      Code.fetch_docs(Req.Steps)

    step_to_doc =
      docs
      |> Enum.into(%{}, fn {{_kind, name, _rity}, _anno, _signature, doc, _metadata} ->
        {name,
         case doc do
           %{"en" => fn_doc} ->
             (String.split(fn_doc, ".") |> hd()) <> "."

           _ ->
             ""
         end}
      end)

    req = Req.new()

    Enum.reduce([:request_steps, :response_steps, :error_steps], %{}, fn stage, acc ->
      steps =
        req
        |> Map.get(stage)
        |> Enum.map(fn {k, _v} ->
          %{"name" => k, "active" => true, "doc" => Map.get(step_to_doc, k)}
        end)

      Map.put(acc, Atom.to_string(stage), steps)
    end)
  end

  def __init__(attrs) do
    default_steps = Map.get(attrs, "steps", get_default_steps())

    %{
      "variable" =>
        attrs["variable"] || Kino.SmartCell.prefixed_var_name("resp", attrs["variable"]),
      "request_type" => attrs["request_type"] || "get",
      "params" => attrs["params"] || [],
      "headers" => attrs["headers"] || [],
      "url" => attrs["url"] || "",
      "verbs" => attrs["verbs"] || Constants.all_verbs(),
      "steps" => default_steps,
      "plugins" => Map.get(attrs, "plugins", Merquery.Plugins.loaded_plugins()),
      "options" => Map.get(attrs, "options", %{})
    }
  end

  @impl true
  def init(attrs \\ %{}, ctx) do
    fields = __init__(attrs)

    ctx =
      assign(ctx,
        fields: fields,
        missing_dep: missing_dep(fields),
        available_plugins: Merquery.Plugins.available_plugins()
      )

    {:ok, ctx}
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      fields: ctx.assigns.fields,
      missing_dep: ctx.assigns.missing_dep,
      available_plugins: ctx.assigns.available_plugins
    }

    {:ok, payload, ctx}
  end

  defp _to_source(attrs, return_req \\ false) do
    using_defaults =
      Enum.all?(
        attrs["steps"]["response_steps"] ++
          attrs["steps"]["request_steps"] ++
          attrs["steps"]["error_steps"],
        fn step -> step["active"] end
      )

    pretty_headers =
      Map.get(attrs, "headers", [])
      |> Enum.filter(&Map.get(&1, "active"))
      |> Enum.map(fn
        %{"key" => key, "value" => value, "isSecretValue" => true} ->
          secret = "LB_#{value}"

          {key, quote(do: System.fetch_env!(unquote(secret)))}

        %{"key" => key, "value" => value} ->
          {key, value}
      end)

    pretty_headers = {:%{}, [], pretty_headers}

    pretty_plugins =
      Map.get(attrs, "plugins", [])
      |> Enum.filter(&Map.get(&1, "active"))
      |> Enum.map(fn %{"name" => name} -> String.to_atom("Elixir.#{name}") end)

    pretty_options = Map.get(attrs, "options", %{}) |> Map.put_new("params", [])

    pretty_options =
      pretty_options
      |> Map.update("params", [], fn params -> params ++ Map.get(attrs, "params", []) end)
      |> Enum.map(fn
        {option, value} when is_list(value) ->
          value =
            Enum.filter(value, &Map.get(&1, "active"))
            |> Enum.map(fn
              %{"key" => key, "value" => value, "isSecretValue" => true} ->
                secret = "LB_#{value}"
                # TODO: Clean this up. Don't like String.to_atom being here. Would rather have
                # Req.Steps.put_path_params support String keys
                key = if option in ["path_params"], do: String.to_atom(key), else: key
                {key, quote(do: System.fetch_env!(unquote(secret)))}

              %{"key" => key, "value" => value} ->
                key = if option in ["path_params"], do: String.to_atom(key), else: key
                {key, value}
            end)

          {String.to_existing_atom(option), {:%{}, [], value}}

        {option, value} ->
          {option, value}
      end)

    req_args = [
      method: String.to_atom(attrs["request_type"]),
      url: attrs["url"],
      headers: pretty_headers
    ]

    steps_block =
      if using_defaults do
        # If using defaults we can use the high-level API
        quote do
          req =
            Req.new(unquote(req_args ++ pretty_options))
        end
      else
        %{
          "steps" => %{
            "request_steps" => default_request,
            "response_steps" => default_response,
            "error_steps" => default_error
          }
        } = attrs

        new_req = Req.new()

        request_steps =
          default_request
          |> Enum.filter(&Map.get(&1, "active", true))
          |> Enum.map(fn step -> step |> Map.get("name") |> String.to_existing_atom() end)

        request_steps =
          new_req |> Map.get(:request_steps) |> Enum.filter(fn {k, _v} -> k in request_steps end)

        response_steps =
          default_response
          |> Enum.filter(&Map.get(&1, "active", true))
          |> Enum.map(fn step -> step |> Map.get("name") |> String.to_existing_atom() end)

        response_steps =
          new_req
          |> Map.get(:response_steps)
          |> Enum.filter(fn {k, _v} -> k in response_steps end)

        error_steps =
          default_error
          |> Enum.filter(&Map.get(&1, "active", true))
          |> Enum.map(fn step -> step |> Map.get("name") |> String.to_existing_atom() end)

        error_steps =
          new_req |> Map.get(:error_steps) |> Enum.filter(fn {k, _v} -> k in error_steps end)

        # We pass the options keys to Req.Request.register_options/1 since they should be validated
        # beforehand -- we don't need Req to do it and it clutters the generated code
        quote do
          req =
            Req.Request.new(unquote(req_args))
            |> Req.Request.register_options(unquote(Keyword.keys(pretty_options)))
            |> Req.merge(unquote(pretty_options))
            |> Req.Request.append_request_steps(unquote(request_steps))
            |> Req.Request.append_response_steps(unquote(response_steps))
            |> Req.Request.append_error_steps(unquote(error_steps))
        end
      end

    plugin_block =
      quote do
        req =
          Enum.reduce(unquote(pretty_plugins), req, fn plugin, acc -> plugin.attach(acc) end)
      end

    run_block =
      quote do
        {req, unquote(quoted_var(attrs["variable"]))} = Req.request(req)
        unquote(quoted_var(attrs["variable"]))
      end

    blocks =
      cond do
        return_req ->
          [steps_block]

        pretty_plugins == [] ->
          [steps_block, run_block]

        true ->
          [steps_block, plugin_block, run_block]
      end

    blocks
    |> Enum.map(&Kino.SmartCell.quoted_to_string/1)
    |> Enum.join("\n")
  end

  @impl true
  def to_source(attrs) do
    _to_source(attrs)
  end

  @impl true
  def to_attrs(%{assigns: %{fields: fields}}) do
    fields
  end

  @impl true
  def handle_event("update_fields", %{} = fields, ctx) do
    ctx = update(ctx, :fields, fn _ -> fields end)

    missing_dep = missing_dep(fields)

    ctx =
      if missing_dep == ctx.assigns.missing_dep do
        ctx
      else
        broadcast_event(ctx, "missing_dep", %{"dep" => missing_dep})
        assign(ctx, missing_dep: missing_dep)
      end

    {:noreply, ctx}
  end

  def handle_event("refreshPlugins", _, %{assigns: %{fields: fields}} = ctx) do
    loaded_plugins = Merquery.Plugins.loaded_plugins()

    updated_fields =
      Map.update(fields, "plugins", [], fn plugins ->
        (plugins ++ loaded_plugins) |> Enum.uniq_by(&Map.get(&1, "name"))
      end)

    ctx =
      update(ctx, :fields, fn _ -> updated_fields end)

    broadcast_event(ctx, "update", %{"fields" => updated_fields})
    {:noreply, ctx}
  end

  def handle_event("importCurlCommand", curlCommand, ctx) do
    req =
      try do
        curlCommand
        |> CurlReq.Macro.parse()
        |> CurlReq.Macro.to_req()
      rescue
        MatchError ->
          nil
      end

    unless is_nil(req) do
      fields =
        %{
          "variable" => Kino.SmartCell.prefixed_var_name("resp", nil),
          "request_type" => req.method |> Atom.to_string(),
          "params" =>
            URI.decode_query(req.url.query)
            |> Enum.map(fn {k, v} ->
              %{"key" => k, "value" => v, "active" => true, "isSecretValue" => false}
            end),
          "headers" =>
            req.headers
            |> Enum.map(fn {k, v} ->
              %{"key" => k, "value" => v, "active" => true, "isSecretValue" => false}
            end),
          "url" => "#{req.url.scheme}://#{req.url.host}#{req.url.path}",
          "verbs" => Constants.all_verbs(),
          "steps" => get_default_steps(),
          "plugins" => Merquery.Plugins.loaded_plugins(),
          "options" => %{}
        }

      ctx =
        update(ctx, :fields, fn _ -> fields end)

      broadcast_event(ctx, "update", %{"fields" => fields})
    else
      broadcast_event(ctx, "curlError", %{})
    end

    {:noreply, ctx}
  end

  def handle_event("copyAsCurlCommand", _, %{assigns: %{fields: fields}} = ctx) do
    {req, _} = _to_source(fields, true) |> Code.eval_string()
    curlCommand = CurlReq.to_curl(req)
    broadcast_event(ctx, "copyAsCurlCommand", curlCommand)
    {:noreply, ctx}
  end

  def handle_event(
        "addDep",
        %{"depString" => depString},
        ctx
      ) do
    {dep, _} = Code.eval_string(depString)

    livebook_pids =
      Node.list(:connected)
      |> Enum.flat_map(fn n ->
        :rpc.call(n, :erlang, :processes, [])
        |> Enum.map(fn pid ->
          info = :rpc.call(n, Process, :info, [pid])
          {pid, info}
        end)
        |> Enum.filter(fn {_pid, info} ->
          case info[:dictionary][:"$initial_call"] do
            {Livebook.Session, _, _} -> true
            _ -> false
          end
        end)
        |> Enum.map(fn {pid, _} -> pid end)
      end)

    livebook_pid =
      livebook_pids
      |> Enum.find(fn pid ->
        :sys.get_state(pid)
        |> Map.get(:client_pids_with_id)
        |> Enum.any?(fn {_k, v} -> v == ctx.origin end)
      end)

    GenServer.cast(
      livebook_pid,
      {:add_dependencies, [%{dep: dep, config: []}]}
    )

    {:noreply, ctx}
  end

  defp missing_dep(%{"plugins" => plugins}) do
    for %{"name" => name, "active" => true, "version" => version} <- plugins do
      unless Code.ensure_loaded?(String.to_existing_atom(name)) do
        version
      end
    end
    |> Enum.join("\n")
  end

  defp quoted_var(string), do: {String.to_atom(string), [], nil}
end
