# Run it from root with ix run examples/simple_xml.exs
defmodule XMLStreamTools.Parser.Helpers do
  import NimbleParsec

  def maybe_escaped_char(combinator \\ empty(), char) do
    combinator
    |> choice([
      ignore(ascii_char([?\\])) |> ascii_char([char]),
      ascii_char([{:not, char}])
    ])
  end

  def quote_by_delimiter(combinator \\ empty(), char) do
    combinator
    |> ignore(ascii_char([char]))
    |> repeat(maybe_escaped_char(char))
    |> ignore(ascii_char([char]))
    |> reduce({List, :to_string, []})
  end
end

defmodule XMLStreamTools.Parser do
  import NimbleParsec
  import XMLStreamTools.Parser.Helpers

  @doc """
  Basic XML Parser, parses to a stream of tags and text.  This makes it possible to process XML as a stream.
  """
  defparsec :element, parsec(:node), debug: true # |> concat(repeat(parsec(:node))) |> eos()

  tag_chars = [?a..?z, ?A..?Z, ?0..?9, ?_]
  tag_id = ascii_string(tag_chars, min: 1)
  ns_id = ascii_string([?: | tag_chars], min: 1)
  namespace = tag_id |> ignore(string(":")) |> tag(:namespace) |> reduce(:deconvolute)
  tag = optional(namespace) |> concat(tag_id) |> tag(:tag) |> reduce(:deconvolute)
  ws = ascii_string([?\s], min: 1)
  
  defcombinatorp :attribute,
    ignore(optional(ws))
    |> concat(ns_id)
    |> ignore(optional(ws))
    |> ignore(string("="))
    |> ignore(optional(ws))
    |> parsec(:quoted_string)
    |> reduce(:into_keyword)

  defcombinatorp :open_tag,
    ignore(optional(ws))
    |> ignore(string("<"))
    |> line() |> byte_offset() |> reduce(:add_loc)
    |> concat(tag)
    |> optional(parsec(:attribute) |> repeat() |> tag(:attr)) 
    |> reduce(:filter_empty_attr)
    |> choice([
      string("/>") |> tag(:close) |> reduce(:set_true),
      ignore(string(">"))
    ])
    |> reduce(:deconvolute)
    |> reduce(:sort)
    |> unwrap_and_tag(:open_tag)
 
  defcombinatorp :close_tag,
    ignore(optional(ws))
    |> ignore(string("</"))
    |> line() |> byte_offset() |> reduce(:add_loc)
    |> concat(tag)
    |> ignore(string(">"))
    |> reduce(:close_deconvolute)
    |> unwrap_and_tag(:close_tag)

  defcombinatorp :text,
    ascii_string([not: ?<], min: 1)
    |> line() |> byte_offset() |> reduce(:add_loc)
    |> unwrap_and_tag(:text)

  defcombinatorp :quoted_string,
    choice([quote_by_delimiter(?"), quote_by_delimiter(?')])   #" help the formatters

  defcombinatorp :node,
    choice([parsec(:open_tag), parsec(:close_tag), parsec(:text)])

  
  defp reverse(_rest, list, context, _line, _offset) do
    {Enum.reverse(list), context}
  end

  defp into_keyword([k | [v]]), do: {k, v}

  defp close_deconvolute([loc | [{:tag, _} = tag]]), do: [tag] ++ loc
  defp close_deconvolute([loc | [tag]]), do: tag ++ loc
  
  defp deconvolute([{tag, [ns|[t]]}]), do: [{tag, t}, ns]
  defp deconvolute([{tag, [h|_t]}]), do: {tag, h}
  defp deconvolute([list, {:close, true}=h]), do: [h | list]
  defp deconvolute([{:tag, name}]), do: [tag: name]
  defp deconvolute([[loc: loc], tag]), do: [{:loc, loc} | tag]
  defp deconvolute([list]), do: list

  defp filter_empty_attr([loc, {:tag, tag}, {:attr, []}]), do: [tag: tag] ++ loc
  defp filter_empty_attr([loc, tag, {:attr, []}]), do: tag ++ loc
  defp filter_empty_attr([loc, {:tag, tag}, attr]), do: [attr | [tag: tag] ] ++ loc
  defp filter_empty_attr([loc, tag, attr]), do: [attr | tag ] ++ loc

  defp set_true([{:close, _}]), do: {:close, true}

  defp add_loc([{[{[], line}] ,offset}]), do: [loc: {line, offset}]
  defp add_loc([{[{[data], line}], offset}]), do: [data, loc: {line, offset}]

  defp add_line_and_offset([{[{[{label, tag}], line}], offset}]), do: {label, tag, line, offset}
#  defp add_line([{[{label, tag}], line}]), do: {label, tag, line}

  defp sort([list]) do
    key_order = [:tag, :namespace, :attr]
    index = fn list, item -> Enum.find_index(list, &Kernel.==(&1, item)) end
    Enum.sort_by(list, fn {k, _} -> index.(key_order, k) end)
  end
  
  def parse_next({"", loc, offset}), do: {:halt, {"", loc, offset}}
  def parse_next({xml, loc, offset}) do
    {:ok, [next_item], rest, _, loc, offset} = element__0(xml, [], [], [], loc, offset)
    {[next_item], {rest, loc, offset}}
  end

  def parse(xml) do
    Stream.resource(
      fn -> {xml, {1, 0}, 0} end,
      &parse_next/1,
      fn _ -> :ok end
    )
  end
end


