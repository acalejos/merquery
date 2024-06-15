# Merquery

[![Twitter Follow](https://img.shields.io/twitter/follow/ac_alejos?style=social)](https://twitter.com/ac_alejos)

https://github.com/acalejos/merquery/assets/12536734/11cd3b60-62fe-4f4f-ad9a-8afeda3a3a0a

Powered by the wonderful [`Req`](https://hexdocs.pm/req/readme.html) library, Merquery is an interactive and extensible
HTTP client for [Elixir](https://elixir-lang.org/) and [Livebook](https://livebook.dev/). Conveniently packaged as a Livebook
SmartCell, you can just add Merquery as a dependency to any Livebook notebook then have access to it under the `Smart` menu
when adding a new cell.

Although Merquery is made with Elixir developers in mind, anyone can use it as an interactive HTTP client, but to take advantage of
features such as code generation, `mix merquery.generate`, and writing custom plugins, you will need to write Elixir.

Merquery currently consists of 2 components:

* `Merquery` Smart Cell that provides an interactive way to work with HTTP requests, akin to Postman
* A `mix` task -- `mix merquery.generate` -- which introspects on your router and generates
`Merquery` smart cells pre-filled with the information relevant to each route.

`Merquery` takes advantage of the Livebook ecosystem to have built-in support for serialization
and secret storage, so you can save queries for later usage and use keys from your Livebook
Hub token vault.

It also can be used to generate source code just as all Smart Cells do. You can use `Merquery`
as a learning tool to learn how to use Elixir HTTP clients.

## Features

* Supports REST operations
* Easily toggle Req [Steps](https://hexdocs.pm/req/Req.Steps.html#content) to customize the request behavior
* Import/export to/from cURL (thanks to [`CurlReq`](https://github.com/derekkraan/curl_req))
* Supports plaintext, secret / environment variables, and custom binding variables in headers, parameters, and body fields.
* Supports various body content types:
  * `application/x-www-urlencoded` with toggleable fields and support for secrets and custom variables (transforms to an Elixir map and uses the `:form` Req option)
  * Raw field to support many content types with syntax highlighting and taking advantage of Req's [`encode_body`](https://hexdocs.pm/req/Req.Steps.html#encode_body/1) step:
    * `application/json` allows you to write JSON and have it converted to an Elixir map and use the `:json` Req option.
    * `application/javascript`
    * `application/xml`
    * `text/html`
    * `text/plain`
* Includes an escape hatch to passthrough custom options to the `Req` request using the `Options` tab. Accepts an Elixir `Keyword` to
  merge with the top-level options.
* Convert to code cell (generates Elixir code for the given request)
* Persists state as Livebook `attr` so you can pick up where you last left off
* With `mix merquery.generate`, you can generate Merquery smart cells from your Phoenix routes, and can even pass default parameters
  for each route using the `:metadata` option from the Phoenix router helpers

  ```elixir
  get "/files/:id", FileController, :show, metadata: %{merquery: [path_params: [id: 1], headers: [accept: "application/json"]]}
  ```

## Plugins

Merquery takes advantage of the Req Plugin API to extend the functionality of the HTTP client. You can read more about Req Plugins [here](https://hexdocs.pm/req/Req.Request.html#module-writing-plugins).

There is a list of curated plugins in Merquery (you can see the list [here](https://github.com/acalejos/merquery/blob/main/lib/merquery/plugins.ex)), but you can make your own plugins or add other plugins that are not explicitly defined in `Merquery.Plugins` so long as the module exports an `attach/1` function and is loaded. None of the plugins in `Merquery.Plugins` ship with Merquery, but Merquery supports easily adding them through the `Plugins` tab (feel free to suggest more plugins too!).

Once a plugin is available in Merquery, you can toggle it on and off, just as you can most key-value parameters in Merquery.

## Options

`Req` accepts many different options in its top-level API (or when creating a new `Req.Request` struct) that change the behavior
of the request. Plugins also might define their own options that they accept. Since it would be impossible to handle the
variety of acceptable option values through key/value pairs, the `Option` tab offers a way to passthrough custom Elxir
options in the form of a keyword list. It also supports using previously bound variables.

## Installation

```elixir
def deps do
  [
    {:merquery, github: "acalejos/merquery"}
  ]
end
```

## Development

From within the `assets` directory run `npm i` and `npm run dev`

This should download all dependencies and run a watchful Vite build. This will put the newly built
assets into the appropriate folder and watch for changes.

## Roadmap

Currently, this is just a fun project I am working on and this roadmap is subject to change.
You may submit feature requests in the form of a GitHub issue.

These are just some ideas for features I currently have, but are subject to change:

* [X] Finish basic REST operations support
* [X] Registering custom plugins
* [ ] Improve `mix merquery.generate`
  * [X] Allow customized parameters for routes, etc.
  * [ ] Add Table of Contents at Top
* [X] Migrate to TailwindCSS
* [ ] Use a distinctive design palette
* [ ] Req plugin discoverability - Host a location where Req plugins can be submitted for others to
discover for use with `Merquery` (*Currently done within this project*)
* [ ] Livebook routes instant deploy - Have a mix task (e.g. `mix merquery.deploy`) to automatically
deploy the generated livebook from `mix merquery.generate`
* [ ] ~~Support other HTTP clients and their unique features (HTTPoison, Tesla, etc. )~~ *(EDIT: Forgoing the idea of pluggable clients and instead focusing entirely on Req)*
* [X] Move Vue to Composition API and breakout components to SPCs *(EDIT: Keeping options API for now, but moved to using SFCs)*
* [ ] Import from OpenAPI Spec
* [X] Import/export to/from cURL
