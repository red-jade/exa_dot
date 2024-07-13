defmodule Exa.Dot.Render do
  @moduledoc """
  Render directed graph in GraphViz DOT format.

  DOT files are rendered to PNG or SVG, 
  iff [GraphViz](https://graphviz.org/docs/layouts/dot/) is installed.
  """
  require Logger
  use Exa.Dot.Constants

  @exe :dot

  @typedoc "Allowed output rendering formats."
  @type format() :: :bmp | :dot | :fig | :gif | :pdf | :ps | :ps2 | :plain | :png | :svg

  # @doc "Get the DOT installed executable path."
  # @spec installed() :: nil | E.filename()
  # def installed(), do: Exa.System.installed(@exe)

  # @doc """
  # Ensure that target executable is installed and accessible 
  # on the OS command line (PATH), otherwise raise an error.
  # """
  # @spec ensure_installed!() :: E.filename()
  # def ensure_installed!(), do: Exa.System.ensure_installed!(@exe)

  @doc """
  Render a DOT file.

  Assumes GraphViz is installed.

  If the input file path does not have a filetype, 
  then the default `.dot` is appended.

  If the `out_dir` is not specified,
  then the output is written to the input directory.

  The return value is the full path to the output file.
  """
  @spec render_dot(Path.t(), format(), nil | String.t()) :: String.t() | {:error, any()}
  def render_dot(in_path, format \\ :png, out_dir \\ nil) when is_atom(format) do
    in_path = to_string(in_path)
    fmt = format |> to_string() |> String.downcase()
    in_path = Exa.File.ensure_type(in_path, to_string(@filetype_dot))
    name = Path.basename(in_path) |> String.split(".", trim: true) |> hd()
    out_file = name <> "." <> fmt

    out_dir =
      if is_nil(out_dir) do
        Path.dirname(in_path)
      else
        Exa.File.ensure_dir!(out_dir)
      end

    out_path = Path.join([out_dir, out_file])

    opts = [stderr_to_stdout: true]

    # case installed() do
    case @exe |> to_string() |> System.find_executable() do
      nil ->
        msg = "GraphViz 'dot' not installed"
        Logger.error(msg)
        {:error, msg}

      _exe ->
        Logger.info("Write #{String.upcase(fmt)} file: #{out_path}")

        case System.cmd(to_string(@exe), ["-T#{fmt}", in_path, "-o", out_path], opts) do
          {_, 0} -> out_path
          err -> {:error, err}
        end
    end
  rescue
    err -> {:error, err}
  end
end
