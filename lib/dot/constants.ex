defmodule Exa.Dot.Constants do
  @moduledoc """
  Constants for handling GraphViz DOT format.
  """

  defmacro __using__(_) do
    quote do
      @filetype_dot :dot

      # attribute key for the node alias name
      @alias :alias
    end
  end
end
