defmodule Exa.Dot.DotWriter do
  @moduledoc """
  Utilities to write directed graphs in GraphViz DOT format.
  """
  require Logger

  import Exa.Color.Types
  alias Exa.Color.Col3b

  alias Exa.Text, as: T

  import Exa.Indent, except: [reduce: 3]
  alias Exa.Indent, as: I

  import Exa.Types

  use Exa.Dot.Constants
  alias Exa.Dot.Types, as: D

  # constants ----------

  # list of characters to escape in labels
  @label_escapes ~c<"'>

  # types ----------

  @typep id() :: String.t() | pos_integer() | atom()
  defguardp is_id(id) when is_nonempty_string(id) or is_pos_int(id) or is_atom(id)

  # something from which node or edge attributes can be extracted
  # local attribute keywords or global graph attributes
  @typep attrs() :: D.attr_kw() | D.graph_attrs()

  # something from which an alias can be extracted
  # optional alias String, or local attribute keywords, or global graph attributes
  @typep alian() :: nil | String.t() | attrs()

  # document ----------

  @doc """
  Create a new empty DOT document.

  The argument is a name to be used for the 
  internal graph structure (default: "mydot")
  """
  @spec new_dot(String.t()) :: I.indent()
  def new_dot(name \\ "mydot"), do: indent() |> open_graph(name)

  @doc "Close the document and return the textdata."
  @spec end_dot(I.indent()) :: T.textdata()
  def end_dot(io), do: io |> close_graph() |> to_text()

  @doc "Write DOT text data to file."
  @spec to_file(T.textdata(), String.t()) :: T.textdata()
  def to_file(text, filename) do
    Exa.File.to_file_text(text, filename)
  end

  # pass through reduce for piping DOT info into text
  @spec reduce(I.indent(), Enumerable.t(), (any(), I.indent() -> I.indent())) :: I.indent()
  defp reduce(io, xs, fun), do: Enum.reduce(xs, io, fun)

  # graph and subgraph ----------

  @doc "Open a new named graph."
  @spec open_graph(I.indent(), String.t()) :: I.indent()
  def open_graph(io, name), do: io |> txtl(["digraph ", name, " {"]) |> push()

  @doc "Open a named subgraph."
  @spec open_subgraph(I.indent()) :: I.indent()
  def open_subgraph(io, name), do: io |> txtl(["subgraph ", name, " {"]) |> push()

  @doc "Open an anonymous subgraph."
  @spec open_subgraph(I.indent()) :: I.indent()
  def open_subgraph(io), do: io |> chr(?{) |> endl() |> push()

  @doc "Close a graph or subgraph."
  @spec close_graph(I.indent()) :: I.indent()
  def close_graph(io), do: io |> pop() |> chr(?}) |> endl()

  # attributes ----------

  @doc """
  A single top-level standalone attribute.
  The attribute appears on its own, outside any node or edge.
  """
  @spec attribute(I.indent(), String.t() | atom(), any()) :: I.indent()
  def attribute(io, k, v), do: txtl(io, attr(k, v))

  # specific top-level attributes

  @doc "Set the rankdir graph attribute."
  @spec rankdir(I.indent(), D.rankdir()) :: I.indent()
  def rankdir(io, rankdir), do: attribute(io, :rankdir, rankdir)

  @doc "Set the size graph attribute: width and height in inches."
  @spec size(I.indent(), number(), number()) :: I.indent()
  def size(io, w, h), do: attribute(io, :size, {w, h})

  @doc "Set the fixedsize graph attribute."
  @spec fixedsize(I.indent(), bool()) :: I.indent()
  def fixedsize(io, fixed?), do: attribute(io, :fixedsize, fixed?)

  @doc "Set the fontname attribute."
  @spec fontname(I.indent(), String.t()) :: I.indent()
  def fontname(io, font), do: attribute(io, :fontname, font)

  # nodes ------------

  @doc """
  Write a top-level property with optional alias or attributes.

  Use the id `:node` or `:edge`.
  Top-level properties use a node textual format.
  """
  @spec global(I.indent(), :node | :edge, alian()) :: I.indent()
  def global(io, id, alian \\ nil) when id in [:node, :edge] do
    node(io, id, alian)
  end

  @doc "Write a node with optional alias or attributes."
  @spec node(I.indent(), id(), alian()) :: I.indent()
  def node(io, id, alian \\ nil) when is_id(id) do
    {i, attrs} = id_attrs!(id, alian)
    io |> newl() |> txt(i) |> attrs(attrs) |> chr(?;) |> endl()
  end

  @doc """
  Write a compact list of nodes, without attributes, on one line.
  The optional graph attributes are only for aliases.
  """
  @spec nodes(I.indent(), [id(), ...], D.graph_attrs()) :: I.indent()
  def nodes(io, ids, gattrs \\ %{}) when is_list(ids) do
    io
    |> newl()
    |> reduce(ids, fn id, io ->
      {i, _attrs} = id_attrs!(id, gattrs)
      txt(io, [i, "; "])
    end)
    |> endl()
  end

  # edges ----------

  @doc """
  Write an edge with optional aliases or attributes.

  The attributes are:
  - global to provide both node aliases
  - just keywords for edges attribute, without aliases
  """
  @spec edge(I.indent(), id(), id(), D.graph_attrs() | D.attr_kw()) :: I.indent()
  def edge(io, id, jd, attrs \\ []) when is_id(id) and is_id(jd) do
    {i, _} = id_attrs!(id, attrs)
    {j, _} = id_attrs!(jd, attrs)
    # edge attributes do not have aliases
    eattrs =
      cond do
        is_keyword(attrs) -> attrs
        is_map(attrs) -> Map.get(attrs, {id, jd}, [])
      end

    io |> newl() |> txt([i, " -> ", j]) |> attrs(eattrs) |> chr(?;) |> endl
  end

  @doc """
  Write a compact list of edge pairs, without attributes, all on one line.
  The graph attributes are just to find the node aliases.
  """
  @spec edges(I.indent(), [{id(), id()}], D.graph_attrs()) :: I.indent()
  def edges(io, edges, gattrs \\ %{})
      when is_list(edges) and edges != [] and is_tuple(hd(edges)) do
    io
    |> newl()
    |> reduce(edges, fn {id, jd}, io ->
      {i, _} = id_attrs!(id, gattrs)
      {j, _} = id_attrs!(jd, gattrs)
      txt(io, [i, " -> ", j, "; "])
    end)
    |> endl()
  end

  @doc """
  Write a chain of edges, without attributes, all on one line.
  The graph attributes supply the node aliases.
  """
  @spec chain(I.indent(), [id()], D.graph_attrs()) :: I.indent()
  def chain(io, [id | ids], gattrs \\ %{}) when ids != [] and is_id(id) do
    {i, _} = id_attrs!(id, gattrs)

    io
    |> newl()
    |> txt(i)
    |> reduce(ids, fn jd, io ->
      {j, _} = id_attrs!(jd, gattrs)
      txt(io, [" -> ", j])
    end)
    |> chr(?;)
    |> endl()
  end

  # -----------------
  # private functions
  # -----------------

  # embedded list of attributes enclosed in square brackets: `[...]`
  @spec attrs(I.indent(), D.attr_kw()) :: I.indent()
  defp attrs(io, []), do: io

  defp attrs(io, [{k, v} | attrs]) do
    txt(io, [?\s, ?[, attr(k, v), Enum.map(attrs, fn {k, v} -> [", ", attr(k, v)] end), ?]])
  end

  # convert attribute to text data, with key equals value 
  @spec attr(String.t() | atom(), any()) :: T.textdata()
  defp attr(:label, v), do: ["label=", esc(v)]
  defp attr(k, v), do: [to_string(k), ?=, val(v)]

  # convert an attribute value to text data
  @spec val(any()) :: T.textdata()

  defp val(col) when is_col3f(col) do
    {r, g, b} = col
    [?", Enum.join([r, g, b], ","), ?"]
  end

  defp val(col) when is_col3b(col), do: [?", Col3b.to_hex(col, :rgb), ?"]

  defp val({x, y}), do: [?", val(x), ?,, val(y), ?"]

  defp val(v), do: T.term_to_text(v)

  # quote and escape a string label
  @spec esc(String.t()) :: T.textdata()
  defp esc(str), do: [?", Exa.String.escape(str, @label_escapes), ?"]

  # validate an id and convert to a string
  @spec id_attrs!(id(), alian()) :: {String.t(), D.attr_kw()}
  defp id_attrs!(id, alian) when is_id(id) do
    {name, _attrs} = id_attrs = alian(id, alian)

    if not Exa.String.valid_name?(name) do
      msg = "Illegal node identifier: '#{name}'"
      Logger.error(msg)
      raise ArgumentError, message: msg
    end

    id_attrs
  end

  # get an alias from an alias/attribute argument
  # return any attributes for rendering without the alias
  @spec alian(id(), alian()) :: {String.t(), D.attr_kw()}
  defp alian(i, nil), do: {to_string(i), []}
  defp alian(_, str) when is_string(str), do: {str, []}
  defp alian(i, map) when is_map(map), do: alian(i, map[i])

  defp alian(i, kw) when is_keyword(kw) do
    case kw[@alias] do
      nil -> {to_string(i), kw}
      al -> {al, Keyword.delete(kw, @alias)}
    end
  end
end
