defmodule Merquery.SmartCell do
  use Kino.JS, assets_path: "assets/build"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Merquery"
  alias Merquery.Helpers.State
  import Flint.Schema, only: [dump: 1]

  alias Merquery.Schemas.{
    Steps,
    Query,
    Flask,
    Plugin,
    Auth,
    Options,
    Body
  }

  @impl true
  def init(attrs \\ %{}, ctx)

  def init(%{queries: []}, ctx) do
    init(%{}, ctx)
  end

  def init(%{queries: _queries, queryIndex: _queryIndex} = attrs, ctx) do
    flask = Flask.new(attrs)

    ctx =
      assign(ctx,
        fields: flask |> dump(),
        missing_dep: missing_dep(flask),
        available_plugins:
          Merquery.Plugins.available_plugins()
          |> Enum.map(&dump/1)
      )

    {:ok, ctx}
  end

  def init(attrs = %{}, ctx) do
    new_query = Query.new(attrs) |> dump()
    flask = Flask.new(%{queries: [new_query], queryIndex: 0})

    ctx =
      assign(ctx,
        fields: flask |> dump(),
        missing_dep: missing_dep(flask),
        available_plugins:
          Merquery.Plugins.available_plugins()
          |> Enum.map(&dump/1)
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

  defp _to_source(%Flask{queries: []}, _) do
    quote do
      nil
    end
    |> Kino.SmartCell.quoted_to_string()
  end

  defp _to_source(%Flask{queries: queries, queryIndex: queryIndex}, return_req) do
    queries |> Enum.at(queryIndex) |> _to_source(return_req)
  end

  defp _to_source(query = %Query{}, return_req) do
    using_defaults = Query.using_default_steps?(query)
    pretty_headers = Query.to_quoted(query, :headers)
    pretty_params = Query.to_quoted(query, :params)
    pretty_plugins = Query.to_quoted(query, :plugins)
    pretty_options = Query.to_quoted(query, :options)
    pretty_auth = Query.to_quoted(query, :auth)
    pretty_body = Query.to_quoted(query, :body)

    req_args =
      [
        method: query.request_type,
        url: query.url,
        headers: pretty_headers,
        params: pretty_params
      ] ++ pretty_body ++ pretty_auth

    steps_block =
      if using_defaults do
        # If using defaults we can use the high-level API
        quote do
          req =
            Req.new(unquote(req_args))
        end
      else
        %Query{
          steps: %Steps{
            request_steps: default_request,
            response_steps: default_response,
            error_steps: default_error
          }
        } = query

        new_req = Req.new()

        request_steps =
          default_request
          |> Enum.filter(&Map.get(&1, :active, true))
          |> Enum.map(fn step -> step |> Map.get(:name) |> String.to_existing_atom() end)

        request_steps =
          new_req |> Map.get(:request_steps) |> Enum.filter(fn {k, _v} -> k in request_steps end)

        response_steps =
          default_response
          |> Enum.filter(&Map.get(&1, :active, true))
          |> Enum.map(fn step -> step |> Map.get(:name) |> String.to_existing_atom() end)

        response_steps =
          new_req
          |> Map.get(:response_steps)
          |> Enum.filter(fn {k, _v} -> k in response_steps end)

        error_steps =
          default_error
          |> Enum.filter(&Map.get(&1, :active, true))
          |> Enum.map(fn step -> step |> Map.get(:name) |> String.to_existing_atom() end)

        error_steps =
          new_req |> Map.get(:error_steps) |> Enum.filter(fn {k, _v} -> k in error_steps end)

        quote do
          req =
            Req.Request.new(unquote(req_args))
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
        {req, unquote(quoted_var(query.variable))} = Req.request(req)
        unquote(quoted_var(query.variable))
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
  def to_source(%Flask{} = flask) do
    _to_source(flask)
  end

  def to_source(flask = %{}) do
    _to_source(Flask.new(flask))
  end

  @impl true
  def to_attrs(%{assigns: %{fields: flask}}) do
    flask
  end

  @impl true
  def scan_binding(pid, binding, _env) do
    send(pid, {:scan_binding_result, binding})
  end

  @impl true
  def handle_info({:scan_binding_result, binding}, ctx) do
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
  def handle_event(
        event,
        payload,
        %{assigns: %{fields: fields}} = ctx
      ) do
    flask = Flask.new(fields)
    handle_event(event, payload, ctx, flask)
  end

  def handle_event("update_fields", %{} = payload, ctx, %Flask{queryIndex: index} = flask) do
    flask =
      flask
      |> Map.update!(:queries, fn queries ->
        List.update_at(queries, index, fn _ -> Query.new(payload) end)
      end)

    ctx = assign(ctx, fields: flask |> dump())

    missing_dep = missing_dep(Query.new(payload))

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
        ctx,
        %Flask{queries: queries} = flask
      ) do
    updated_flask =
      %{flask | queries: queries ++ [Query.new()], queryIndex: length(queries)}
      |> dump()

    ctx =
      update(ctx, :fields, fn _ ->
        updated_flask
      end)

    broadcast_event(ctx, "update", %{"fields" => updated_flask})
    {:noreply, ctx}
  end

  def handle_event(
        "selectQueryTab",
        index,
        ctx,
        %Flask{} = flask
      ) do
    updated_flask = %{flask | queryIndex: index} |> dump()

    ctx =
      update(ctx, :fields, fn _ ->
        updated_flask
      end)

    broadcast_event(ctx, "update", %{"fields" => updated_flask})
    {:noreply, ctx}
  end

  def handle_event(
        "deleteQueryTab",
        index,
        ctx,
        %Flask{queries: prevQueries, queryIndex: prevIndex} = flask
      )
      when is_number(index) do
    newIndex =
      cond do
        prevIndex == index && index == 0 ->
          0

        prevIndex < index ->
          prevIndex

        true ->
          prevIndex - 1
      end

    updated_flask =
      %{flask | queries: List.delete_at(prevQueries, index), queryIndex: newIndex}
      |> dump()

    ctx =
      update(ctx, :fields, fn _ ->
        updated_flask
      end)

    broadcast_event(ctx, "update", %{"fields" => updated_flask})
    {:noreply, ctx}
  end

  def handle_event(
        "updateRaw",
        %{"raw" => newRaw, "target" => target},
        ctx,
        %Flask{queryIndex: queryIndex} = flask
      ) do
    updated_flask =
      update_in(
        flask,
        [:queries, Access.at(queryIndex), String.to_existing_atom(target), :raw],
        fn _raw -> newRaw end
      )

    ctx =
      update(ctx, :fields, fn _ ->
        updated_flask
      end)

    {:noreply, ctx}
  end

  def handle_event("refreshPlugins", _, ctx, %Flask{queryIndex: queryIndex} = flask) do
    loaded_plugins = Merquery.Plugins.loaded_plugins()

    updated_flask =
      update_in(flask, [:queries, Access.at!(queryIndex), :plugins], fn plugins ->
        (plugins ++ Enum.map(loaded_plugins, &Plugin.new/1)) |> Enum.uniq_by(&Map.get(&1, :name))
      end)
      |> dump()

    ctx =
      update(ctx, :fields, fn _ -> updated_flask end)

    broadcast_event(ctx, "update", %{"fields" => updated_flask})
    {:noreply, ctx}
  end

  def handle_event(
        "importFromString",
        string,
        ctx,
        %Flask{queries: queries} = flask
      ) do
    ctx =
      case Jason.decode(string) do
        {:ok, %{"queries" => importedQueries}} ->
          updated_flask =
            %{flask | queries: queries ++ Enum.map(importedQueries, &Query.new/1)}
            |> dump()

          ctx =
            update(ctx, :fields, fn _ ->
              updated_flask
            end)

          broadcast_event(ctx, "update", %{"fields" => updated_flask})
          ctx

        _ ->
          req =
            try do
              string
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
                {:bearer, token} ->
                  %{value: token, scheme: :bearer}

                {:basic, credentials} ->
                  %{value: credentials, scheme: :basic}

                _ ->
                  %{value: "", scheme: :none}
              end

            new_query =
              Query.new(%{
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
                "body" =>
                  Body.new(%{
                    contentType: contentType,
                    form: form,
                    raw:
                      if(contentType in ["none", "application/x-www-form-urlencoded"],
                        do: "",
                        else: req.body
                      )
                  }),
                "options" => Options.new(%{raw: "", contentType: "elixir"}),
                "auth" => Auth.new(auth)
              })

            updated_flask =
              %{flask | queries: queries ++ [new_query], queryIndex: length(queries)}
              |> dump()

            ctx =
              update(ctx, :fields, fn _ ->
                updated_flask
              end)

            broadcast_event(ctx, "update", %{"fields" => updated_flask})
            ctx
          else
            broadcast_event(ctx, "curlError", %{})
            ctx
          end
      end

    {:noreply, ctx}
  end

  def handle_event("copyAsCurlCommand", _, ctx, %Flask{} = flask) do
    {req, _} = _to_source(flask, true) |> Code.eval_string()
    curlCommand = CurlReq.to_curl(req, run_steps: [except: [:auth]])
    broadcast_event(ctx, "copyAsCurlCommand", curlCommand)
    {:noreply, ctx}
  end

  def handle_event(
        "importFromFile",
        {:binary, %{"filename" => _filename, "mimeType" => "application/json"}, binary},
        ctx,
        %Flask{queries: queries} = flask
      ) do
    ctx =
      case Jason.decode(binary) do
        {:ok, %{"queries" => importedQueries}} ->
          updated_flask =
            %{flask | queries: queries ++ Enum.map(importedQueries, &Query.new/1)}
            |> dump()

          ctx =
            update(ctx, :fields, fn _ ->
              updated_flask
            end)

          broadcast_event(ctx, "update", %{"fields" => updated_flask})
          ctx

        _ ->
          broadcast_event(ctx, "curlError", %{})
          ctx
      end

    {:noreply, ctx}
  end

  def handle_event("exportAsJson", _, ctx, %Flask{} = flask) do
    case Jason.encode(flask) do
      {:ok, encoded} ->
        reply_payload = {:binary, nil, encoded}
        broadcast_event(ctx, "downloadSaveAsJson", reply_payload)

      {:error, _error} ->
        broadcast_event(ctx, "curlError", %{})
    end

    {:noreply, ctx}
  end

  def handle_event(
        "addDep",
        %{"depString" => depString},
        ctx,
        _flask
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

  defp missing_dep(%Flask{queries: queries, queryIndex: queryIndex}) do
    query = queries |> Enum.at(queryIndex)

    missing_dep(query)
  end

  defp missing_dep(%Query{plugins: plugins}) do
    for %Plugin{name: name, active: true, version: version} <- plugins do
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
