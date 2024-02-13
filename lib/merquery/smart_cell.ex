defmodule Merquery.SmartCell do
  use Kino.JS, assets_path: "lib/assets"
  use Kino.JS.Live
  use Kino.SmartCell, name: "Merquery"

  @common_fields ["variable", "client", "request_type", "params", "headers", "url"]
  @all_verbs ["get", "post", "put", "patch", "delete", "head"]

  @impl true
  def init(attrs, ctx) do
    client = attrs["client"] || default_client()

    fields = %{
      "variable" => Kino.SmartCell.prefixed_var_name("resp", attrs["variable"]),
      "client" => client,
      "request_type" => attrs["request_type"] || "get",
      "params" => attrs["params"] || [],
      "headers" => attrs["headers"] || [],
      "url" => attrs["url"] || "",
      "verbs" => attrs["verbs"] || @all_verbs
    }

    fields =
      if Code.ensure_loaded?(Req) do
        Map.put(fields, "req", Merquery.Clients.Req.Adapter.init(attrs["req"] || %{}))
      end

    ctx =
      assign(ctx,
        fields: fields,
        missing_dep: missing_dep(fields)
      )

    {:ok, ctx}
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      fields: ctx.assigns.fields,
      missing_dep: ctx.assigns.missing_dep
    }

    {:ok, payload, ctx}
  end

  @impl true
  def to_source(attrs) do
    case attrs["client"] do
      "req" -> Merquery.Clients.Req.Adapter.to_source(attrs)
      _ -> []
    end
  end

  @impl true
  def to_attrs(%{assigns: %{fields: fields}}) do
    client_field = Map.get(fields, "client", default_client())
    Map.take(fields, [client_field | @common_fields])
  end

  defp default_client() do
    cond do
      Code.ensure_loaded?(Req) -> "req"
      Code.ensure_loaded?(HTTPoison) -> "httpoison"
      Code.ensure_loaded?(Tesla) -> "tesla"
      true -> "req"
    end
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

  defp missing_dep(%{"req" => %{"plugins" => plugins}}) do
    for %{"name" => name, "active" => true, "version" => version} <- plugins do
      unless Code.ensure_loaded?(Merquery.Clients.Req.Plugins.plugin_to_module(%{"name" => name})) do
        version
      end
    end
    |> Enum.join("\n")
  end

  defp missing_dep(%{"client" => "req"}) do
    unless Code.ensure_loaded?(Req) do
      ~s/{:req, "~> 0.4"}/
    end
  end

  defp missing_dep(%{"client" => "httpoison"}) do
    unless Code.ensure_loaded?(HTTPoison) do
      ~s/{:httpoison, "~> 2.2"}/
    end
  end

  defp missing_dep(%{"client" => "Tesla"}) do
    unless Code.ensure_loaded?(Tesla) do
      ~s/{:tesla, "~> 1.4"}/
    end
  end
end
