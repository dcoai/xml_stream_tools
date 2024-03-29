# XML Stream Tools

This is an Elixir library of tools for manipulate XML with using Streams.

Tools:

- a NimbleParsec XML parser
- a transformer - this can be used to take the stream of XML elements and output another stream of
  modified elements or anything else really.
- an inspector, which will write stream elements to the console, as they are processed.
- a decoder this builds on the transformer and will convert XML to elixir Maps.  As part of this
  there is an Elixir Behaviour called Formatter which is defined to specify how to convert the
  XML to a Map.  New implementations of this behaviour can be defined to change how the XML is
  converted.  For example if your XML lends itself to going into an Explorer structure, that
  is possible to create with the Formatter.

# The dreaded To Do section:

- write some documentation, so other people can find this useful.
- make an inspect that writes to Logger
- make a filter that takes XPath like input to select or exclude XML from the stream
- make an encoder protocol.  To encode Maps, Lists and Structs into XML


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `xmlstreamtools` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:xmlstreamtools, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/xmlstreamtools>.

