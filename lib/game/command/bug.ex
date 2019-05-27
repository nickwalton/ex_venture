defmodule Game.Command.Bug do
  @moduledoc """
  The "bug" command
  """

  use Game.Command
  use Game.Command.Editor

  alias Data.Bug
  alias Data.Repo
  alias Game.Bugs
  alias Game.Format.Bugs, as: Format

  commands(["bugs", "bug"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Bug"
  def help(:short), do: "Report a bug"

  def help(:full) do
    """
    Report a bug you encounter to the game admins. After entering a title you will
    be able to enter in multi line text for further information.

    Example:
    [ ] > {command}bug title{/command}
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Bug.parse("bugs")
      {:list}

      iex> Game.Command.Bug.parse("bug my title")
      {:new, "my title"}

      iex> Game.Command.Bug.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  @spec parse(String.t()) :: {any()}
  def parse(command)
  def parse("bugs"), do: {:list}
  def parse("bugs read " <> id), do: {:read, id}
  def parse("bug read " <> id), do: {:read, id}
  def parse("bug " <> title), do: {:new, title}
  def parse("bug"), do: {:unknown}

  @impl Game.Command
  def run(command, state)

  def run({:list}, state) do
    bugs = Bugs.reported_by(state.character)
    state |> Socket.echo(Format.list_bugs(bugs))
  end

  def run({:read, id}, state) do
    case Bugs.get(state.character, id) do
      {:error, :not_found} ->
        state |> Socket.echo("Bug ##{id} not found.")

      {:ok, bug} ->
        state |> Socket.echo(Format.show_bug(bug))
    end
  end

  def run({:new, bug_title}, state) do
    message =
      "Please enter in any more information you have (an empty new line will finish entering text): "

    state |> Socket.echo(message)

    commands =
      state
      |> Map.get(:commands, %{})
      |> Map.put(:bug, %{title: bug_title, lines: []})

    {:editor, __MODULE__, Map.put(state, :commands, commands)}
  end

  def run({:unknown}, state) do
    message =
      "Please provide a bug title. See {command}help bug{/command} for more information."

    state |> Socket.echo(message)
  end

  @impl Game.Command.Editor
  def editor({:text, line}, state) do
    bug = Map.get(state.commands, :bug, %{})
    lines = Map.get(bug, :lines) ++ [line]
    bug = Map.put(bug, :lines, lines)
    state = %{state | commands: %{state.commands | bug: bug}}

    {:update, state}
  end

  def editor(:complete, state) do
    bug = state.commands.bug

    params = %{
      title: bug.title,
      body: bug.lines |> Enum.join("\n"),
      reporter_id: state.character.id
    }

    create_bug(state, params)

    commands =
      state
      |> Map.get(:commands)
      |> Map.delete(:bug)

    {:update, Map.put(state, :commands, commands)}
  end

  defp create_bug(state, params) do
    changeset = %Bug{} |> Bug.changeset(params)

    case changeset |> Repo.insert() do
      {:ok, _bug} ->
        state |> Socket.echo("Your bug has been submitted. Thanks!")

      {:error, changeset} ->
        error =
          Enum.map(changeset.errors, fn {field, error} ->
            human_error = Web.ErrorHelpers.translate_error(error)
            "#{field} #{human_error}"
          end)

        message = "There was an issue creating the bug."
        state |> Socket.echo("#{message}\n#{error}")
    end
  end
end
