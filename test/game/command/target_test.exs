defmodule Game.Command.TargetTest do
  use ExVenture.CommandCase

  alias Game.Character
  alias Game.Command.Target

  doctest Target

  setup do
    npc = %Character.Simple{id: 1, type: "npc", name: "Bandit"}

    start_room(%{
      npcs: [npc],
      players: [%Character.Simple{id: 2, type: "player", name: "Player"}]
    })

    user = base_user()
    character = base_character(user)

    %{state: session_state(%{user: user, character: character})}
  end

  test "set your target from someone in the room", %{state: state} do
    {:update, state} = Game.Command.Target.run({:set, "bandit"}, state)

    assert %{type: "npc", id: 1} = state.target

    assert_socket_echo "now targeting"
    assert_socket_gmcp {"Target.Character", _}
  end

  test "targeting another player", %{state: state} do
    {:update, state} = Game.Command.Target.run({:set, "player"}, state)

    assert %{type: "player", id: 2} = state.target

    assert_socket_echo "now targeting"
    assert_socket_gmcp {"Target.Character", _}
  end

  test "targeting yourself", %{state: state} do
    {:update, state} = Game.Command.Target.run({:set, "self"}, state)

    character_id = state.character.id
    assert %{type: "player", id: ^character_id} = state.target

    assert_socket_echo "now targeting"
    assert_socket_gmcp {"Target.Character", _}
  end

  test "target not found", %{state: state} do
    :ok = Game.Command.Target.run({:set, "unknown"}, state)

    assert_socket_echo "could not"
  end

  test "viewing your target - npc", %{state: state} do
    state = %{state | target: %{type: "npc", id: 1}}
    :ok = Game.Command.Target.run({}, state)

    assert_socket_echo "your target is"
  end

  test "viewing your target - npc no longer there", %{state: state} do
    state = %{state | target: %{type: "npc", id: 2}}
    :ok = Game.Command.Target.run({}, state)

    assert_socket_echo "could not"
  end

  test "viewing your target - player", %{state: state} do
    state = %{state | target: %{type: "player", id: 2, name: "Player"}}
    :ok = Game.Command.Target.run({}, state)

    assert_socket_echo "your target is"
  end

  test "viewing your target - user no longer there", %{state: state} do
    state = %{state | target: %{type: "player", id: 3}}
    :ok = Game.Command.Target.run({}, state)

    assert_socket_echo "could not"
  end

  test "viewing your target - missing", %{state: state} do
    state = %{state | target: nil}
    :ok = Game.Command.Target.run({}, state)

    assert_socket_echo "don't have"
  end
end
