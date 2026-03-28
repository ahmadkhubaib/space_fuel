defmodule SpaceFuel.MissionStepTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.MissionStep

  test "exposes supported actions and planets" do
    assert MissionStep.actions() == ["launch", "land"]
    assert MissionStep.planets() == ["Earth", "Moon", "Mars"]
  end

  test "accepts valid step attributes" do
    changeset = MissionStep.changeset(%MissionStep{}, %{"action" => "launch", "planet" => "Mars"})

    assert changeset.valid?
    assert Ecto.Changeset.apply_action!(changeset, :validate) == %MissionStep{
             action: "launch",
             planet: "Mars"
           }
  end

  test "requires a valid action and planet" do
    changeset = MissionStep.changeset(%MissionStep{}, %{"action" => nil, "planet" => "Venus"})

    refute changeset.valid?
    assert {"can't be blank", _} = Keyword.fetch!(changeset.errors, :action)
    assert {"is invalid", _} = Keyword.fetch!(changeset.errors, :planet)
  end
end
