defmodule Merquery.Helpers do
  @moduledoc false
  def quoted_var(string), do: {String.to_atom(string), [], nil}
end
