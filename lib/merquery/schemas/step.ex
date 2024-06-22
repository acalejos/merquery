defmodule Merquery.Schemas.Step do
  use Merquery.Schema,
    schema: [field(:active, :boolean, default: true), field(:doc, :string), field(:name, :string)]
end
