defmodule Merquery.Clients.Req.Adapter do
  defimpl Kino.Render, for: Req.Request do
    def to_livebook(req) do
      Kino.Tree.new(req) |> Kino.Render.to_livebook()
    end
  end

  defimpl Kino.Render, for: Req.Response do
    def to_livebook(resp) do
      Kino.Tree.new(resp) |> Kino.Render.to_livebook()
    end
  end

  def init(attrs) do
    default_steps = get_in(attrs, ["req", "steps"])

    default_steps =
      unless is_nil(default_steps) do
        default_steps
        |> Map.put_new("request_steps", [])
        |> Map.put_new("response_steps", [])
        |> Map.put_new("error_steps", [])
      else
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

    %{
      "steps" => default_steps,
      "plugins" => Map.get(attrs, "plugins", Merquery.Clients.Req.Plugins.plugins()),
      "options" => Map.get(attrs, "options", [])
    }
  end

  defp existing_atom?(str) when is_binary(str) do
    try do
      String.to_existing_atom(str) && true
    rescue
      ArgumentError ->
        false
    end
  end

  defp quoted_var(string), do: {String.to_atom(string), [], nil}

  def to_source(%{"client" => "req"} = attrs) do
    attrs |> to_quoted()
  end

  defp to_quoted(attrs) do
    using_defaults =
      Enum.all?(
        attrs["req"]["steps"]["response_steps"] ++
          attrs["req"]["steps"]["request_steps"] ++
          attrs["req"]["steps"]["error_steps"],
        fn step -> step["active"] end
      )

    pretty_params =
      Map.get(attrs, "params", [])
      |> Enum.filter(&Map.get(&1, "active"))
      |> Enum.map(fn
        %{"key" => key, "value" => value, "isSecretValue" => true} ->
          secret = "LB_#{value}"

          {key, quote(do: System.fetch_env!(unquote(secret)))}

        %{"key" => key, "value" => value} ->
          {key, value}
      end)

    pretty_params = {:%{}, [], pretty_params}

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
      (get_in(attrs, ["req", "plugins"]) || [])
      |> Enum.filter(&Map.get(&1, "active"))
      |> Enum.map(&Merquery.Clients.Req.Plugins.plugin_to_module/1)
      |> Enum.filter(&Code.ensure_loaded?/1)

    pretty_options =
      (get_in(attrs, ["req", "options"]) || [])
      |> Enum.filter(&Map.get(&1, "active"))
      |> Enum.map(fn
        %{"key" => key, "value" => value, "isSecretValue" => true} ->
          secret = "LB_#{value}"

          {String.to_existing_atom(key),
           quote do
             System.fetch_env(unquote(secret))
           end}

        %{"key" => key, "value" => value} ->
          {String.to_existing_atom(key), value}
      end)

    setup_block =
      quote do
        params = unquote(pretty_params)
        headers = unquote(pretty_headers)

        url = unquote(attrs["url"])
      end

    steps_block =
      if using_defaults do
        # If using defaults we can use the high-level API
        quote do
          req =
            Req.new(
              unquote_splicing(pretty_options),
              method: unquote(String.to_atom(attrs["request_type"])),
              url: url,
              params: params,
              headers: headers
            )
        end
      else
        %{
          "steps" => %{
            "request_steps" => default_request,
            "response_steps" => default_response,
            "error_steps" => default_error
          }
        } = attrs["req"]

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

        quote do
          req =
            Req.Request.new(
              unquote_splicing(pretty_options),
              method: unquote(String.to_atom(attrs["request_type"])),
              url: url,
              params: params,
              headers: headers
            )
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
      case pretty_plugins do
        [] ->
          [setup_block, steps_block, run_block]

        _ ->
          [setup_block, steps_block, plugin_block, run_block]
      end

    blocks
    |> Enum.map(&Kino.SmartCell.quoted_to_string/1)
    |> Enum.join("\n")
  end
end
