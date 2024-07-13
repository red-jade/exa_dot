defmodule Exa.Dot.DotReaderTest do
  use ExUnit.Case

  use Exa.Dot.Constants
  import Exa.Dot.DotReader

  @in_dir ["test", "input", "dot"]
  # ["abcd", "squares", "petersen"]
  @in_files ["petersen"]

  defp file(name), do: Exa.File.join(@in_dir, name, @filetype_dot)

  # DOT input ---------

  test "missing file" do
    dne = "File does not exist"
    in_file = file("xyz")
    {:error, %File.Error{path: ^in_file, action: ^dne}} = from_dot(in_file)
  end

  test "small" do
    {graph, gattrs} = from_dot(file("small"))

    assert [
             {1, 2},
             {2, 3},
             {1, 4},
             {1, 5},
             {3, 6},
             {3, 7},
             {4, 6},
             {1, 7},
             {3, 8}
           ] ==
             graph

    assert [alias: "parse"] == gattrs[2]
    assert [alias: "execute"] == gattrs[3]
  end

  test "test123" do
    {graph, gattrs} = from_dot(file("test123"))
    assert [{1, 2}, {2, 3}, {1, 4}, 2, 3, {1, 5}, {4, 5}, {2, 4}, 6, 8, 9, {8, 9}] == graph
    assert [alias: "b", shape: "box"] == gattrs[2]

    assert [
             alias: "c",
             style: "filled",
             fontcolor: "red",
             fontname: "Palatino-Italic",
             fontsize: "24",
             color: "blue",
             label: "hello world"
           ] == gattrs[3]

    assert [weight: "100", label: "hi"] == gattrs[{1, 5}]
    assert [label: "multi-line\\nlabel"] == gattrs[{4, 5}]

    assert [fontname: "Helvetica"] == gattrs["test123_node"]
    assert [style: "dashed"] == gattrs["test123_edge"]
    assert [penwidth: "2.0"] == gattrs["test123"]
  end

  test "dot input" do
    for file <- @in_files do
      {_graph, _gattrs} = from_dot(file(file))
      # IO.inspect(graph, label: "graph ")
      # IO.inspect(gattrs, label: "attrs")
    end
  end
end
