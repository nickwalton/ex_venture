defmodule Game.Session.Channels do
  @moduledoc """
  Implementation for channel callbacks
  """

  alias Game.Hint
  alias Game.Player
  alias Game.Session.GMCP
  alias Game.Session.State
  alias Game.Socket

  @doc """
  Call back for joining a channel
  """
  @spec joined(State.t(), String.t()) :: State.t()
  def joined(state = %{save: save}, channel) do
    channels =
      [channel | save.channels]
      |> Enum.into(MapSet.new())
      |> Enum.into([])

    Player.update_save(state, %{save | channels: channels})
  end

  @doc """
  Callback for leaving a channel
  """
  @spec left(State.t(), String.t()) :: State.t()
  def left(state = %{save: save}, channel) do
    channels = Enum.reject(save.channels, &(&1 == channel))
    Player.update_save(state, %{save | channels: channels})
  end

  @doc """
  Callback for receiving a broadcast on a channel
  """
  @spec broadcast(State.t(), String.t(), Message.t()) :: State.t()
  def broadcast(state, channel, message) do
    state |> Socket.echo(message.formatted)
    state |> GMCP.channel_broadcast(channel, message)
    state
  end

  @doc """
  Callback for receiving a tell
  """
  @spec tell(State.t(), Character.t(), Message.t()) :: State.t()
  def tell(state, from, message) do
    state |> Socket.echo(message.formatted)
    state |> GMCP.tell(from, message)

    state
    |> maybe_hint_tell(from)
    |> Map.put(:reply_to, from)
  end

  def maybe_hint_tell(state = %{reply_to: nil}, %{type: "npc"}) do
    Hint.gate(state, "tells.new_npc")
    state
  end

  def maybe_hint_tell(state = %{reply_to: nil}, %{type: "player"}) do
    Hint.gate(state, "tells.new")
    state
  end

  def maybe_hint_tell(state, _), do: state
end
