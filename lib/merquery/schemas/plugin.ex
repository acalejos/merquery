defmodule Merquery.Schemas.Plugin do
  use Merquery.Schema,
    schema: [
      field(:active, :boolean, default: true),
      field(:description, :string),
      field(:name, :string),
      field(:version, :string)
    ]
end
