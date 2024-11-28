defmodule Merquery.Schemas.Query do
  alias Merquery.Schemas.{Auth, Options, MultiInput, Body, Plugin, Steps}
  alias Merquery.Helpers.{Constants, State}
  alias Merquery.Helpers

  use Flint.Schema

  @request_types [:get, :post, :put, :patch, :delete, :head, :options]

  embedded_schema do
    embeds_one :auth, Auth
    embeds_one :body, Body
    embeds_many :params, MultiInput
    embeds_many :headers, MultiInput
    embeds_one :options, Options
    embeds_many :plugins, Plugin
    embeds_one :steps, Steps

    field :request_type, Ecto.Enum,
      values: @request_types,
      default: :get

    field :url, :string, default: ""
    field :variable, :string, default: ""

    field :verbs, {:array, Ecto.Enum},
      values: @request_types,
      default: @request_types
  end

  def new(params \\ %{}, bindings \\ []) do
    params =
      params
      |> Map.put_new_lazy("steps", fn -> Steps.default_steps() |> Ecto.embedded_dump(:json) end)
      |> Map.put_new_lazy("plugins", fn -> Merquery.Plugins.loaded_plugins() end)
      |> Map.put_new_lazy("variable", fn -> Kino.SmartCell.prefixed_var_name("resp", nil) end)
      |> Map.put_new_lazy("verbs", fn -> Constants.all_verbs() end)

    %__MODULE__{}
    |> changeset(params, bindings)
    |> Ecto.Changeset.apply_changes()
  end

  def using_default_steps?(query) do
    Enum.all?(
      query.steps.response_steps ++
        query.steps.request_steps ++
        query.steps.error_steps,
      fn step -> step.active end
    )
  end

  def to_quoted(%__MODULE__{} = query, field) when field in [:headers, :params] do
    quoted =
      Map.get(query, field, [])
      |> Enum.filter(&Map.get(&1, :active))
      |> Enum.map(&MultiInput.to_quoted/1)

    {:%{}, [], quoted}
  end

  def to_quoted(%__MODULE__{} = query, :plugins) do
    query.plugins
    |> Enum.filter(&Map.get(&1, :active))
    |> Enum.map(fn %Plugin{name: name} -> String.to_atom("Elixir.#{name}") end)
  end

  def to_quoted(%__MODULE__{} = query, :options) do
    try do
      bindings =
        State.get_bindings()

      {body, _bindings} = Code.eval_string(query.options.raw, bindings)

      if Keyword.keyword?(body) do
        body
      else
        []
      end
    rescue
      _ ->
        []
    end
  end

  def to_quoted(%__MODULE__{auth: %{scheme: :none}}, :auth), do: []

  def to_quoted(%__MODULE__{} = query, :auth) do
    %{value: value, scheme: scheme, type: type} = query.auth

    evald_value =
      case type do
        :secret ->
          secret = "LB_#{value}"

          quote(do: System.fetch_env!(unquote(secret)))

        :plaintext ->
          value

        :variable ->
          quote(do: unquote(Helpers.quoted_var(value)))
      end

    case scheme do
      :bearer ->
        [auth: {:bearer, evald_value}]

      :basic ->
        [auth: {:basic, evald_value}]

      :netrc ->
        if String.trim(value) == "", do: [auth: :netrc], else: [auth: {:netrc, evald_value}]

      :string ->
        [auth: evald_value]
    end
  end

  def to_quoted(%__MODULE__{body: %{contentType: :none}}, :body), do: []

  def to_quoted(%__MODULE__{body: %{contentType: contentType, raw: raw}}, :body)
      when contentType in [:plaintext, :javascript, :html, :xml],
      do: [body: raw]

  def to_quoted(%__MODULE__{body: %{contentType: :elixir, raw: raw}}, :body) do
    try do
      bindings =
        State.get_bindings()

      {body, _bindings} = Code.eval_string(raw, bindings)
      [body: body]
    rescue
      _ ->
        [body: raw]
    end
  end

  def to_quoted(%__MODULE__{body: %{contentType: contentType, raw: raw}}, :body) when contentType in [:json, :json_api, :graphql] do
    case Jason.decode(raw) do
      {:ok, json} ->
        [json: json]

      {:error, _} ->
        [body: raw]
    end
  end

  def to_quoted(%__MODULE__{body: %{contentType: :form, form: form}}, :body) do
    form_data =
      form
      |> Enum.filter(&Map.get(&1, :active))
      |> Enum.map(fn
        %{key: key, value: value, type: :secret} ->
          secret = "LB_#{value}"

          {key, quote(do: System.fetch_env!(unquote(secret)))}

        %{key: key, value: value, type: :plaintext} ->
          {key, value}

        %{key: key, value: value, type: :variable} ->
          {key, quote(do: unquote(Helpers.quoted_var(value)))}
      end)

    form_data = {:%{}, [], form_data}
    [form: form_data]
  end
end
