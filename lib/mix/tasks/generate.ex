defmodule Mix.Tasks.Merquery.Generate do
  @moduledoc """
  Introspects on your project looking at all routes and creates a new Livebook
  with Merquery Smart Cells pre-populated to interactively test your routes.

  Currently only supports Phoenix Routers.

  ## Options

  * `--router` - The module of your router. Defaults to the default Phoenix Router.
  * `--out` - Path to save the generated file. Defaults to `merquery.livemd`
  * `--base-url` - Base URL to append to all generated routes. Defaults to `https://0.0.0.0`
  """
  @shortdoc "Generates a Livebook to test your defined routes"
  use Mix.Task
  @requirements ["app.start"]

  if Code.ensure_loaded?(Phoenix.Router) do
    import Merquery.Helpers.Constants
    alias Merquery.Schemas.{Query, Flask}

    @impl Mix.Task
    def run(args) do
      case Mix.Task.get("phx.routes") do
        Mix.Tasks.Phx.Routes ->
          Mix.Task.run("compile", args)
          base = Mix.Phoenix.base()

          {opts, _args, _} =
            OptionParser.parse(args, switches: [router: :string, out: :string, base_url: :string])

          opts =
            Keyword.validate!(opts,
              router: nil,
              out: "merquery.json",
              base_url: "http://0.0.0.0"
            )

          router_mod =
            case opts[:router] do
              nil -> router(opts[:router], base)
              passed_router -> router(passed_router, base)
            end

          match_all = :*

          queries =
            for {%{path: path, verb: verb, metadata: metadata}, index} <-
                  Enum.with_index(Phoenix.Router.routes(router_mod)),
                verb == match_all or verb in all_verbs() or
                  (is_list(verb) && Enum.all?(&Kernel.in(&1, all_verbs()))) do
              # We infer some attrs from the route information
              auto_attrs =
                %{
                  "request_type" =>
                    case verb do
                      :* ->
                        :get

                      verb when is_verb(verb) ->
                        verb

                      _ ->
                        raise ArgumentError,
                              "Invalid method `#{verb}`. Allowed methods are `#{inspect(all_verbs())}`"
                    end,
                  "url" => "#{opts[:base_url]}#{path}",
                  "variable" => "resp#{index}",
                  "verbs" =>
                    case verb do
                      :* ->
                        all_verbs()

                      v when is_list(v) ->
                        v

                      v when is_verb(v) ->
                        [v]
                    end
                }

              # We collect the attrs provided as an option in the route
              usr_attrs =
                metadata
                |> Map.get(:merquery, %{})
                |> then(&if(Keyword.keyword?(&1), do: Enum.into(&1, %{}), else: &1))

              {top_level, options} =
                Map.split(usr_attrs, Map.keys(%Query{} |> Map.delete(:options)))

              attrs =
                Enum.reduce(
                  top_level,
                  if(options != %{},
                    do: %{"options" => %{raw: options |> Enum.into([]) |> inspect()}},
                    else: %{}
                  ),
                  fn
                    {key, headers}, acc when key in [:headers, :params, :plugins] ->
                      # Handle the array-types separately
                      Map.put(
                        acc,
                        to_string(key),
                        Enum.map(headers || [], fn {k, v} ->
                          %{key: to_string(k), value: v}
                        end)
                      )

                    {:method, v}, acc ->
                      Map.put(acc, "request_type", v)

                    {k, v}, acc when is_req_arg(k) ->
                      Map.put(acc, to_string(k), v)

                    {k, v}, acc when is_merquery_opt(k) ->
                      Map.put(acc, to_string(k), v)

                    _, acc ->
                      acc
                  end
                )

              Map.merge(auto_attrs, attrs) |> Query.new()
            end

          %{queries: queries}
          |> Flask.new!()
          |> Jason.encode!()
          |> then(&File.write!(opts[:out], &1))

        nil ->
          Mix.shell().info("Currently this tasks only supports Phoenix Routers")
      end
    end

    # From Mix.Tasks.Phx.Routes
    defp router(nil, base) do
      if Mix.Project.umbrella?() do
        Mix.raise("""
        umbrella applications require an explicit router to be given to phx.routes, for example:

            $ mix phx.routes MyAppWeb.Router

        An alias can be added to mix.exs aliases to automate this:

            "phx.routes": "phx.routes MyAppWeb.Router"

        """)
      end

      web_router = web_mod(base, "Router")
      old_router = app_mod(base, "Router")

      loaded(web_router) || loaded(old_router) ||
        Mix.raise("""
        no router found at #{inspect(web_router)} or #{inspect(old_router)}.
        An explicit router module may be given to phx.routes, for example:

            $ mix phx.routes MyAppWeb.Router

        An alias can be added to mix.exs aliases to automate this:

            "phx.routes": "phx.routes MyAppWeb.Router"

        """)
    end

    defp router(router_name, _base) do
      arg_router = Module.concat([router_name])

      loaded(arg_router) ||
        Mix.raise("the provided router, #{inspect(arg_router)}, does not exist")
    end

    defp loaded(module) do
      if Code.ensure_loaded?(module), do: module
    end

    defp app_mod(base, name), do: Module.concat([base, name])

    defp web_mod(base, name), do: Module.concat(["#{base}Web", name])
  else
    def run(_args) do
      Mix.shell().info(
        "You can only use the `mix merquery.generate` task within a Phoenix project."
      )
    end
  end
end
