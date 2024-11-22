defmodule Merquery.Schemas.Steps do
  alias Merquery.Schemas.Step

  use Flint.Schema

  embedded_schema do
    embeds_many :request_steps, Step
    embeds_many :response_steps, Step
    embeds_many :error_steps, Step
  end

  def default_steps() do
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

    all_steps =
      Enum.reduce([:request_steps, :response_steps, :error_steps], %{}, fn stage, acc ->
        steps =
          req
          |> Map.get(stage)
          |> Enum.map(fn {k, _v} ->
            %{name: Atom.to_string(k), doc: Map.get(step_to_doc, k)}
          end)

        Map.put(acc, stage, steps)
      end)

    __MODULE__.new(all_steps)
  end
end
