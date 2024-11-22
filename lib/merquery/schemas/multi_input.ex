defmodule Merquery.Schemas.MultiInput do
  use Flint.Schema

  embedded_schema do
    field :active, :boolean, default: true
    field :key, :string, default: ""
    field :value, :string, default: ""

    field :type, Merquery.Types.MultiInput, embed_as: :dumped, default: :plaintext
  end

  def to_quoted(%__MODULE__{key: key, value: value, type: :secret}),
    do: {key, quote(do: System.fetch_env!(unquote("LB_#{value}")))}

  def to_quoted(%__MODULE__{key: key, value: value, type: :plaintext}), do: {key, value}

  def to_quoted(%__MODULE__{key: key, value: value, type: :variable}),
    do: {key, quote(do: unquote(Merquery.Helpers.quoted_var(value)))}
end
