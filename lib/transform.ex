defmodule XMLStreamTools.Transformer do
  @moduledoc """
  Apply a transform function to a stream of XML elements.

  the function `fun` is called with each element in the stream, the current stack of open tags and the current accumulator.

  fun is a function that takes three arguments:
  - element: the current element, ex: {:open_tag, %{tag: "foo"}}
  - stack: the current stack of open tags (the path), ex: [ "bar", "foo" ]
  - the current accumulator
  """
  def transform(stream, acc \\ [], fun) do
    stream
    |> Stream.chunk_while(initial_acc(acc, fun), &process_item/2, &after_fn/1)
  end

  defp initial_acc(acc, fun), do: {[], acc, fun}

  defp process_item({:open_tag, parts} = element, {stack, acc, fun}) do
    tag = Keyword.get(parts, :tag)
    stack = [tag | stack]

    fun.(element, stack, acc)
    |> next(stack, fun)
  end

  defp process_item({:text, _} = element, {stack, acc, fun}) do
    fun.(element, stack, acc)
    |> next(stack, fun)
  end

  defp process_item({:close_tag, parts} = element, {[head | stack] = pre_stack, acc, fun}) do
    tag = Keyword.get(parts, :tag)

    cond do
      tag == head ->
        fun.(element, pre_stack, acc)
        |> next(stack, fun)

      tag != head ->
        error(element, "mis-matched close tag #{inspect(tag)}, expecting: #{head}")

      [] == pre_stack ->
        error(element, "unmatched close tag #{inspect(tag)}")
    end
  end

  defp process_item(element, {_, _, _}),
    do: error(element, "unexpected element: #{inspect(element)}")

  defp next({element, acc}, stack, fun), do: {:cont, element, {stack, acc, fun}}
  defp next(acc, stack, fun), do: {:cont, {stack, acc, fun}}

  defp after_fn([]), do: {:cont, []}
  defp after_fn(acc), do: {:cont, acc}

  defp error(element, msg) do
    {{line, line_start}, abs_pos} = element |> elem(1) |> Keyword.get(:loc)
    loc = "line: #{line}, char: #{abs_pos - line_start}"
    raise "Error #{loc}: #{msg}"
  end
end
