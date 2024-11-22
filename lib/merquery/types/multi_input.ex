defmodule Merquery.Types.MultiInput do
  use Flint.Type, extends: Flint.Types.Enum, values: [plaintext: 0, secret: 1, variable: 2]
end
