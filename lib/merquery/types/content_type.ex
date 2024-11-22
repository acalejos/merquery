defmodule Merquery.Schemas.ContentType do
  use Ecto.Type
  def type, do: :atom

  @type_atoms [:json, :none, :plaintext, :javascript, :xml, :form, :elixir, :html]

  def cast("application/json"), do: {:ok, :json}
  def cast("none"), do: {:ok, :none}
  def cast("text/plain"), do: {:ok, :plaintext}
  def cast("application/javascript"), do: {:ok, :javascript}
  def cast("application/xml"), do: {:ok, :xml}
  def cast("application/x-www-form-urlencoded"), do: {:ok, :form}
  def cast("elixir"), do: {:ok, :elixir}
  def cast("text/html"), do: {:ok, :html}
  def cast(type) when type in @type_atoms, do: {:ok, type}

  def cast(_), do: :error

  def load("application/json"), do: {:ok, :json}
  def load("none"), do: {:ok, :none}
  def load("text/plain"), do: {:ok, :plaintext}
  def load("application/javascript"), do: {:ok, :javascript}
  def load("application/xml"), do: {:ok, :xml}
  def load("application/x-www-form-urlencoded"), do: {:ok, :form}
  def load("elixir"), do: {:ok, :elixir}
  def load("text/html"), do: {:ok, :html}
  def load(_), do: :error

  def dump(:json), do: {:ok, "application/json"}
  def dump(:none), do: {:ok, "none"}
  def dump(:plaintext), do: {:ok, "text/plain"}
  def dump(:javascript), do: {:ok, "application/javascript"}
  def dump(:xml), do: {:ok, "application/xml"}
  def dump(:form), do: {:ok, "application/x-www-form-urlencoded"}
  def dump(:elixir), do: {:ok, "elixir"}
  def dump(:html), do: {:ok, "text/html"}
  def dump(_), do: :error

  def embed_as(_) do
    :dump
  end
end
