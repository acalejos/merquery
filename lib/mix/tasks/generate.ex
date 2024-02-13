defmodule Mix.Tasks.Merquery.Generate do
  @moduledoc """
  Introspects on your project looking at all routes and creates a new Livebook
  with Merquery Smart Cells pre-populated to interactively test your routes.

  Currently only supports Phoenix Routers.

  ## Options

  * `:router` - The module of your router. Defaults to the default Phoenix Router.
  * `:out` - Path to save the generated file. Defaults to `merquery.livemd`
  * `:base_url` - Base URL to append to all generated routes. Defaults to `https://0.0.0.0`
  """
  @shortdoc "Generates a Livebook to test your defined routes"

  use Mix.Task

  defp encode_value(%{__struct__: _} = value) do
    value
    |> Map.from_struct()
    |> encode_value
  end

  defp encode_value(value) when is_map(value) do
    Enum.into(value, %{}, fn {k, v} ->
      {encode_value(k), encode_value(v)}
    end)
  end

  defp encode_value(value) when is_list(value) do
    Enum.map(value, &encode_value/1)
  end

  defp encode_value({v1, v2}) do
    %{encode_value(v1) => encode_value(v2)}
  end

  defp encode_value(value) when value in [true, false, nil], do: value

  defp encode_value(value), do: to_string(value)

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("compile", args)

    case Mix.Task.get("phx.routes") do
      Mix.Tasks.Phx.Routes ->
        Mix.Task.run("compile", args)
        base = Mix.Phoenix.base()

        {opts, _args, _} =
          OptionParser.parse(args, switches: [router: :string, out: :string, base_url: :string])

        opts =
          Keyword.validate!(opts, router: nil, out: "merquery.livemd", base_url: "http://0.0.0.0")

        router_mod =
          case opts[:router] do
            nil -> router(opts[:router], base)
            passed_router -> router(passed_router, base)
          end

        allowed_verbs = [:get, :post, :put, :patch, :delete, :head]
        match_all = :*

        deps =
          quote do
            Mix.install([
              {:kino, "~> 0.12"},
              {:merquery, gitub: "acalejos/merquery"},
              {:req, "~> 0.4"}
            ])
          end
          |> Macro.to_string()

        header = """
        # Merquery

        ```elixir
        #{deps}
        ```

        ## Routes
        """

        routes =
          for {%{path: path, verb: verb, metadata: metadata}, index} <-
                Enum.with_index(Phoenix.Router.routes(router_mod)),
              verb == match_all or verb in allowed_verbs do
            parameters = get_in(metadata, [:merquery, :parameters])

            path =
              unless is_nil(parameters) do
                parameters = parameters |> Enum.into(%{})

                path
                |> String.split("/")
                |> Enum.into(<<>>, fn part ->
                  case part do
                    "" ->
                      part

                    <<":"::utf8, rest::binary>> ->
                      current =
                        try do
                          String.to_existing_atom(rest)
                        rescue
                          ArgumentError ->
                            nil
                        end

                      if Map.has_key?(parameters, current) do
                        "/#{Map.fetch!(parameters, current)}"
                      else
                        "/" <> part
                      end

                    _ ->
                      "/" <> part
                  end
                end)
              else
                path
              end

            attrs =
              Map.merge(
                %{
                  "request_type" =>
                    case verb do
                      :* ->
                        "get"

                      _ ->
                        Atom.to_string(verb)
                    end,
                  "url" => "#{opts[:base_url]}#{path}",
                  "client" => "req",
                  "variable" => "resp#{index}",
                  "req" => %{},
                  "verbs" =>
                    case verb do
                      :* ->
                        allowed_verbs

                      _ ->
                        [Atom.to_string(verb)]
                    end
                },
                metadata
                |> Map.get(:merquery, %{})
                |> then(&if(Keyword.keyword?(&1), do: Enum.into(&1, %{}), else: &1))
                |> Map.update(:params, [], fn params ->
                  Enum.map(params, &Merquery.Helpers.Field.new/1)
                end)
                |> Map.update(:headers, [], fn headers ->
                  Enum.map(headers, &Merquery.Helpers.Field.new/1)
                end)
                |> encode_value()
              )

            cell_info = %{
              "attrs" => attrs |> Jason.encode!() |> Base.encode64(padding: false),
              "chunks" => nil,
              "kind" => "Elixir.Merquery.SmartCell",
              "livebook_object" => "smart_cell"
            }

            block_header = "<!-- livebook: #{Jason.encode!(cell_info)} -->"

            src_string =
              case attrs["client"] do
                "req" ->
                  Merquery.SmartCell.to_source(%{
                    attrs
                    | "req" => Merquery.Clients.Req.Adapter.init(attrs)
                  })

                _ ->
                  # TODO Change to a better default
                  Merquery.SmartCell.to_source(%{
                    attrs
                    | "req" => Merquery.Clients.Req.Adapter.init(attrs)
                  })
              end

            block_contents = """
            ```elixir
            #{src_string}
            ```
            """

            block_header <> "\n" <> block_contents
          end

        livemd = Enum.join([header | routes], "\n\n")
        out = Keyword.get(opts, :out, "merquery.livemd")
        File.write!(out, livemd)

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
    loaded(arg_router) || Mix.raise("the provided router, #{inspect(arg_router)}, does not exist")
  end

  defp loaded(module) do
    if Code.ensure_loaded?(module), do: module
  end

  defp app_mod(base, name), do: Module.concat([base, name])

  defp web_mod(base, name), do: Module.concat(["#{base}Web", name])
end
