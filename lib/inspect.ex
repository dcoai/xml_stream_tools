defmodule XMLStreamTools.Inspector do
  @moduledoc """
  XML Inspector: This module is used to inspect the XML stream.

  # Example:

      xml = "<foo a='1'>first element<bar>nested element</bar></foo>"
      XMLStreamTools.Parser.parse(xml)
      |> XMLStreamTools.Transformer.transform(XMLStreamTools.Inspector.inspect_fn(label: "test_stream"))
      |> Enum.map(fn x -> x end)

  """

  def inspect_fn(opts \\ []) do
    options = %{label: Keyword.get(opts, :label, nil)}
    fn element, path, acc -> inspect(element, path, acc, options) end
  end

  def inspect({type, meta}, path, acc, %{label: label}) do
    label = if label != nil, do: "#{label}: ", else: ""
    IO.puts("#{label}{#{inspect(type)}, #{inspect(meta)}}, path: #{inspect(path)}")
  end
end
