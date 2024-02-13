defmodule Merquery.Helpers.Field do
  @moduledoc """
  Helper module for creating serializable fields in the correct format as expected by
  Merquery.SmartCell.
  """

  defstruct [:key, :value, active: true, isSecret: false]

  def new(val \\ [])

  def new([{key, value}]) when is_list(value) do
    struct(__MODULE__, [{:key, key} | value])
  end

  def new([{key, value}]) when is_atom(key) do
    struct(__MODULE__, key: key, value: value)
  end

  def new(key) when is_atom(key) do
    struct(__MODULE__, key: key)
  end

  def new({key, value}) when is_atom(key) and is_list(value) do
    struct(__MODULE__, [{:key, key} | value])
  end

  def new({key, value}) when is_atom(key) do
    struct(__MODULE__, key: key, value: value)
  end

  def new(fields) when is_list(fields) do
    fields
    |> Enum.into(%{})
    |> then(&struct(__MODULE__, &1))
  end
end
