defmodule Merquery.Schema do
  import Ecto.Changeset

  @embeds_one_defaults [defaults_to_struct: true, on_replace: :delete]
  @embeds_many_defaults [on_replace: :delete]

  defmacro __using__(schema: schema) do
    quote do
      @behaviour Access

      defdelegate fetch(term, key), to: Map
      defdelegate get_and_update(term, key, fun), to: Map
      defdelegate pop(data, key), to: Map

      import Merquery.Schema, only: [cast_all: 2]
      use Ecto.Schema

      @primary_key false
      embedded_schema do
        import Ecto.Schema,
          except: [
            embeds_one: 2,
            embeds_one: 3,
            embeds_one: 4,
            embeds_many: 2,
            embeds_many: 3,
            embeds_many: 4
          ]

        import Merquery.Schema, only: :macros

        unquote(schema)
      end

      def new(params \\ %{}) do
        __MODULE__.__struct__()
        |> cast_all(params)
        |> Ecto.Changeset.apply_changes()
      end

      defoverridable new: 1, new: 0

      defimpl Jason.Encoder do
        def encode(value, opts) do
          value |> Ecto.embedded_dump(:json) |> Jason.Encode.map(opts)
        end
      end
    end
  end

  def cast_all(schema, params) do
    response_model = schema.__struct__
    fields = response_model.__schema__(:fields) |> MapSet.new()
    embedded_fields = response_model.__schema__(:embeds) |> MapSet.new()
    params = if is_struct(params), do: Map.from_struct(params), else: params

    fields =
      fields
      |> MapSet.difference(embedded_fields)

    changeset =
      schema
      |> cast(params, fields |> MapSet.to_list())

    changeset =
      for field <- embedded_fields, reduce: changeset do
        changeset ->
          changeset
          |> cast_embed(field, with: &cast_all/2, required: true)
      end

    changeset
  end

  def dump(obj) do
    obj |> Ecto.embedded_dump(:json)
  end

  defmacro embeds_one(name, schema, opts \\ [])

  defmacro embeds_one(name, schema, do: block) do
    quote do
      Ecto.Schema.embeds_one(unquote(name), unquote(schema), unquote(@embeds_one_defaults),
        do: unquote(block)
      )
    end
  end

  defmacro embeds_one(name, schema, opts) do
    quote do
      Ecto.Schema.embeds_one(
        unquote(name),
        unquote(schema),
        unquote(opts) ++ unquote(@embeds_one_defaults)
      )
    end
  end

  defmacro embeds_one(name, schema, opts, do: block) do
    quote do
      Ecto.Schema.embeds_one(
        unquote(name),
        unquote(schema),
        unquote(opts) ++ unquote(@embeds_one_defaults),
        do: unquote(block)
      )
    end
  end

  defmacro embeds_many(name, schema, opts \\ [])

  defmacro embeds_many(name, schema, do: block) do
    quote do
      embeds_many(unquote(name), unquote(schema), unquote(@embeds_many_defaults),
        do: unquote(block)
      )
    end
  end

  defmacro embeds_many(name, schema, opts) do
    quote do
      Ecto.Schema.embeds_many(
        unquote(name),
        unquote(schema),
        unquote(opts) ++ unquote(@embeds_many_defaults)
      )
    end
  end

  @doc """
  Indicates an embedding of many schemas.

  For options and examples see documentation of `embeds_many/3`.
  """
  defmacro embeds_many(name, schema, opts, do: block) do
    quote do
      Ecto.Schema.embeds_many(
        unquote(name),
        unquote(schema),
        unquote(opts) ++ unquote(@embeds_many_defaults),
        do: unquote(block)
      )
    end
  end
end
