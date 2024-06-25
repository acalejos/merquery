defmodule Merquery.Schemas.Step do
  use Flint,
    schema: [field(:active, :boolean, default: true), field(:doc, :string), field(:name, :string)]
end
