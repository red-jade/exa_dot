defmodule Exa.Dot.Types do
  @moduledoc """
  Types for handling GraphViz DOT format.
  """

  # graph format is compatible with Agra agraph gdata format
  # if agraph is moved into Exa, move these types into shared Graph.Types

  @type vert() :: pos_integer()
  @type edge() :: {vert(), vert()}
  @type gelem() :: vert() | edge()
  @type graph() :: [gelem()]

  @typedoc "Attributes for graph elements."
  @type attr_kw() :: Keyword.t(String.t())

  @typedoc "Name of a digraph or nested subgraph (cluster)."
  @type gname() :: String.t()

  @typedoc "Key for attribute map."
  @type gkey() :: gelem() | gname()

  @typedoc """
  A map of maps for node, edge, graph and subgraph (cluster) attributes
  """
  @type graph_attrs() :: %{gkey() => attr_kw()}

  @typedoc """
  Index of alias names to integer id.
  Nodes are identified by integer.
  The 'alias' is the identifier used in the DOT file,
  when the node name is not a raw integer.
  The 'label' is an optional arbitrary string, which can be multi-line.
  A node with an integer id may have an alias, or a label, or both.
  """
  @type aliases() :: %{String.t() => vert()}

  # ----------------------------
  # attribute value enumerations
  # ----------------------------

  @typedoc "Rankdir for the graph: top-to-bottom, left-to-right, etc."
  @type rankdir() :: :TB | :LR | :BT | :RL

  @typedoc "Direction values for arrowheads on edges."
  @type direction() :: :forward | :back | :both | :none

  @typedoc "Styles for nodes and edges."
  @type style() :: :solid | :dashed | :dotted | :bold | :invis | :filled | :diagonals | :rounded

  @typedoc "Rank for nodes."
  @type rank() :: :same | :min | :max | :source | :sink

  @typedoc "Rank for clusters."
  @type cluster_rank() :: :global | :none

  @typedoc "Aspect ratio."
  @type aspect_ratio() :: float() | :fill | :auto

  @typedoc "Orientation for the page."
  @type orientation() :: :landscape | :portrait

  @typedoc """
  Alignment for horizontal jutification (labeljust) 
  and vertical alignment (labelloc)
  """
  @type align() :: :c | :l | :r | :t | :b

  @typedoc "Compass point for edge head/tail attachment ports."
  @type attach_port() :: :n | :ne | :e | :se | :s | :sw | :w | :nw

  @typedoc "Node shape."
  @type shape() ::
          :box
          | :polygon
          | :ellipse
          | :circle
          | :point
          | :egg
          | :triangle
          | :diamond
          | :trapezium
          | :parallelogram
          | :house
          | :hexagon
          | :octagon
          | :doublecircle
          | :doubleoctagon
          | :tripleoctagon
          | :invtriangle
          | :invtrapezium
          | :invhouse
          | :none
          | :Mdiamond
          | :Msquare
          | :Mcircle
          | :record
          | :Mrecord
end
