defmodule Merquery.Schemas.Plugin do
  use Flint,
    schema: [
      field(:active, :boolean, default: true),
      field(:description, :string),
      field(:name, :string),
      field(:version, :string)
    ]
end
