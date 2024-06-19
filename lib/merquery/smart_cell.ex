defmodule Merquery.SmartCell do
  use Kino.JS, assets_path: "assets/build"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Merquery"
  alias Merquery.Helpers.Constants
  alias Merquery.Helpers.State

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

  def __init__(attrs \\ %{}) do
    default_steps = Map.get(attrs, "steps", get_default_steps())

    %{
      "variable" =>
        attrs["variable"] || Kino.SmartCell.prefixed_var_name("resp", attrs["variable"]),
      "request_type" => attrs["request_type"] || "get",
      "params" => attrs["params"] || [],
      "headers" => attrs["headers"] || [],
      "body" =>
        attrs["body"] ||
          %{
            # Options: ["none", "text/plain","application/json","application/javascript","text/html","application/xml", "application/x-www-form-urlencoded"]
            "contentType" => "application/json",
            "raw" => "",
            "form" => []
          },
      "url" => attrs["url"] || "",
      "verbs" => attrs["verbs"] || Constants.all_verbs(),
      "steps" => default_steps,
      "plugins" => Map.get(attrs, "plugins", Merquery.Plugins.loaded_plugins()),
      "options" => attrs["options"] || %{"raw" => "", "contentType" => "elixir"},
      "auth" => attrs["auth"] || %{"type" => 0, "value" => "", "scheme" => "none"}
    }
  end

  @impl true
  def init(attrs \\ %{}, ctx) do
    new_query = __init__(attrs)
    fields = %{"queries" => [new_query], "queryIndex" => 0}

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

  defp _to_source(attrs, return_req \\ false)

  defp _to_source(%{"queries" => []}, _) do
    quote do
      nil
    end
    |> Kino.SmartCell.quoted_to_string()
  end

  defp _to_source(%{"queries" => queries, "queryIndex" => queryIndex}, return_req) do
    queries |> Enum.at(queryIndex) |> _to_source(return_req)
  end

  defp _to_source(attrs, return_req) do
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
        %{"key" => key, "value" => value, "type" => 1} ->
          secret = "LB_#{value}"

          {key, quote(do: System.fetch_env!(unquote(secret)))}

        %{"key" => key, "value" => value, "type" => 0} ->
          {key, value}

        %{"key" => key, "value" => value, "type" => 2} ->
          {key, quote(do: unquote(quoted_var(value)))}
      end)

    pretty_headers = {:%{}, [], pretty_headers}

    pretty_plugins =
      Map.get(attrs, "plugins", [])
      |> Enum.filter(&Map.get(&1, "active"))
      |> Enum.map(fn %{"name" => name} -> String.to_atom("Elixir.#{name}") end)

    pretty_options =
      try do
        bindings =
          State.get_bindings()

        {body, _bindings} = Code.eval_string(get_in(attrs, ["options", "raw"]), bindings)

        if Keyword.keyword?(body) do
          body
        else
          []
        end
      rescue
        _ ->
          []
      end

    auth = Map.get(attrs, "auth", %{"scheme" => "none"})

    pretty_auth =
      if Map.get(auth, "scheme", "none") == "none" do
        []
      else
        %{"value" => value, "scheme" => scheme, "type" => type} = auth

        evald_value =
          case type do
            1 ->
              secret = "LB_#{value}"

              quote(do: System.fetch_env!(unquote(secret)))

            0 ->
              value

            2 ->
              quote(do: unquote(quoted_var(value)))
          end

        case scheme do
          "bearer" ->
            [auth: {:bearer, evald_value}]

          "basic" ->
            [auth: {:basic, evald_value}]

          "netrc" ->
            if String.trim(value) == "", do: [auth: :netrc], else: [auth: {:netrc, evald_value}]

          "string" ->
            [auth: evald_value]
        end
      end

    body =
      attrs
      |> Map.get("body", %{"contentType" => "none"})

    content_type =
      body
      |> Map.get("contentType")

    raw = Map.get(body, "raw")
    form = Map.get(body, "form")

    pretty_body =
      case content_type do
        "none" ->
          []

        "elixir" ->
          try do
            bindings =
              State.get_bindings()

            {body, _bindings} = Code.eval_string(raw, bindings)
            [body: body]
          rescue
            _ ->
              [body: raw]
          end

        "text/plain" ->
          [body: raw]

        "application/json" ->
          case Jason.decode(raw) do
            {:ok, json} ->
              [json: json]

            {:error, _} ->
              [body: raw]
          end

        "application/javascript" ->
          [body: raw]

        "text/html" ->
          [body: raw]

        "application/xml" ->
          [body: raw]

        "application/x-www-form-urlencoded" ->
          form_data =
            form
            |> Enum.filter(&Map.get(&1, "active"))
            |> Enum.map(fn
              %{"key" => key, "value" => value, "type" => 1} ->
                secret = "LB_#{value}"

                {key, quote(do: System.fetch_env!(unquote(secret)))}

              %{"key" => key, "value" => value, "type" => 0} ->
                {key, value}

              %{"key" => key, "value" => value, "type" => 2} ->
                {key, quote(do: unquote(quoted_var(value)))}
            end)

          form_data = {:%{}, [], form_data}
          [form: form_data]
      end

    req_args =
      [
        method: String.to_atom(attrs["request_type"]),
        url: attrs["url"],
        headers: pretty_headers
      ] ++ pretty_body ++ pretty_auth

    steps_block =
      if using_defaults do
        # If using defaults we can use the high-level API
        quote do
          req =
            Req.new(unquote(req_args))
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

    options_block =
      quote do
        req = Req.merge(req, unquote(pretty_options))
      end

    run_block =
      quote do
        {req, unquote(quoted_var(attrs["variable"]))} = Req.request(req)
        unquote(quoted_var(attrs["variable"]))
      end

    blocks =
      cond do
        return_req ->
          [steps_block, options_block]

        pretty_plugins == [] ->
          [steps_block, options_block, run_block]

        true ->
          [steps_block, plugin_block, options_block, run_block]
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
  def to_attrs(%{assigns: %{fields: fields} = assigns, origin: origin} = ctx) do
    Map.put(fields, "origin", origin)
  end

  @impl true
  def scan_binding(pid, binding, _env) do
    send(pid, {:scan_binding_result, binding})
  end

  @impl true
  def handle_info({:scan_binding_result, binding}, %{origin: origin} = ctx) do
    State.update_bindings(binding)

    available_bindings =
      for {key, _val} <- binding,
          is_atom(key),
          do: %{"label" => Atom.to_string(key), "value" => Atom.to_string(key)}

    ctx =
      assign(ctx, available_bindings: available_bindings)

    broadcast_event(ctx, "set_available_bindings", %{
      "available_bindings" => available_bindings
    })

    {:noreply, ctx}
  end

  @impl true
  def handle_event("update_fields", %{} = payload, ctx) do
    ctx =
      update(ctx, :fields, fn %{"queryIndex" => queryIndex} = fields ->
        fields
        |> Map.update!("queries", fn queries ->
          List.update_at(queries, queryIndex, fn _ -> payload end)
        end)
      end)

    missing_dep = missing_dep(payload)

    ctx =
      if missing_dep == ctx.assigns.missing_dep do
        ctx
      else
        broadcast_event(ctx, "missing_dep", %{"dep" => missing_dep})
        assign(ctx, missing_dep: missing_dep)
      end

    {:noreply, ctx}
  end

  def handle_event(
        "addQueryTab",
        _,
        %{assigns: %{fields: %{"queries" => queries} = fields}} = ctx
      ) do
    updated_fields =
      fields
      |> Map.update!("queries", fn queries -> queries ++ [__init__()] end)
      |> Map.update!("queryIndex", fn _ -> length(queries) end)

    ctx =
      update(ctx, :fields, fn _ ->
        updated_fields
      end)

    broadcast_event(ctx, "update", %{"fields" => updated_fields})
    {:noreply, ctx}
  end

  def handle_event(
        "selectQueryTab",
        index,
        %{assigns: %{fields: fields}} = ctx
      ) do
    updated_fields =
      fields
      |> Map.update!("queryIndex", fn _ -> index end)

    ctx =
      update(ctx, :fields, fn _ ->
        updated_fields
      end)

    broadcast_event(ctx, "update", %{"fields" => updated_fields})
    {:noreply, ctx}
  end

  def handle_event(
        "deleteQueryTab",
        index,
        %{assigns: %{fields: fields}} = ctx
      )
      when is_number(index) do
    updated_fields =
      fields
      |> Map.update!("queries", fn prevQueries -> List.delete_at(prevQueries, index) end)
      |> Map.update!("queryIndex", fn prevIndex ->
        cond do
          prevIndex == index && index == 0 ->
            0

          prevIndex < index ->
            prevIndex

          true ->
            prevIndex - 1
        end
      end)

    ctx =
      update(ctx, :fields, fn _ ->
        updated_fields
      end)

    broadcast_event(ctx, "update", %{"fields" => updated_fields})
    {:noreply, ctx}
  end

  def handle_event("updateRaw", %{"raw" => newRaw, "target" => target}, ctx) do
    ctx =
      update(ctx, :fields, fn %{"queryIndex" => queryIndex} = fields ->
        update_in(fields, ["queries", Access.at(queryIndex), target, "raw"], fn _raw -> newRaw end)
      end)

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

  def handle_event(
        "importCurlCommand",
        curlCommand,
        %{assigns: %{fields: %{"queries" => queries} = fields}} = ctx
      ) do
    req =
      try do
        curlCommand
        |> CurlReq.from_curl()
      rescue
        MatchError ->
          nil
      end

    unless is_nil(req) do
      contentType =
        case Map.get(req.headers, "content-type") do
          [type] ->
            type

          types when is_list(types) ->
            hd(types)

          nil ->
            "none"
        end

      form =
        if contentType == "application/x-www-form-urlencoded" do
          URI.decode_query(req.body)
          |> Enum.map(fn {k, v} ->
            %{"key" => k, "value" => v, "active" => true, "type" => 0}
          end)
        else
          []
        end

      auth =
        case Req.Request.get_option(req, :auth) do
          {:bearer, token} -> %{"type" => 0, "value" => token, "scheme" => "bearer"}
          {:basic, credentials} -> %{"type" => 0, "value" => credentials, "scheme" => "basic"}
          _ -> %{"type" => 0, "value" => "", "scheme" => ""}
        end

      new_query =
        %{
          "variable" => Kino.SmartCell.prefixed_var_name("resp", nil),
          "request_type" => req.method |> Atom.to_string(),
          "params" =>
            if(req.url.query,
              do:
                URI.decode_query(req.url.query)
                |> Enum.map(fn {k, v} ->
                  %{"key" => k, "value" => v, "active" => true, "type" => 0}
                end),
              else: []
            ),
          "headers" =>
            req.headers
            |> Enum.map(fn {k, v} ->
              %{"key" => k, "value" => v, "active" => true, "type" => 0}
            end),
          "url" => "#{req.url.scheme}://#{req.url.host}#{req.url.path}",
          "verbs" => Constants.all_verbs(),
          "steps" => get_default_steps(),
          "plugins" => Merquery.Plugins.loaded_plugins(),
          "body" => %{
            "contentType" => contentType,
            "form" => form,
            "raw" =>
              if(contentType in ["none", "application/x-www-form-urlencoded"],
                do: "",
                else: req.body
              )
          },
          "options" => %{"raw" => "", "contentType" => "elixir"},
          # type can be in ["string", "basic", "bearer", "netrc"]
          "auth" => auth
        }

      updated_fields =
        fields
        |> Map.update!("queries", fn _ -> queries ++ [new_query] end)
        |> Map.update!("queryIndex", fn _ -> length(queries) end)

      ctx =
        update(ctx, :fields, fn _ ->
          updated_fields
        end)

      broadcast_event(ctx, "update", %{"fields" => updated_fields})
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

  defp missing_dep(%{"queries" => queries, "queryIndex" => queryIndex}) do
    query = queries |> Enum.at(queryIndex)

    missing_dep(query)
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

defimpl Kino.Render, for: Req.Response do
  def to_livebook(response) do
    Kino.Tree.new(response) |> Kino.Render.to_livebook()
  end
end
