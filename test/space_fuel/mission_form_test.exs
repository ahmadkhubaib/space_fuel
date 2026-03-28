defmodule SpaceFuel.MissionFormTest do
  use ExUnit.Case, async: true

  alias SpaceFuel.MissionForm
  alias SpaceFuel.MissionStep

  test "rejects invalid mass and empty steps" do
    changeset = MissionForm.changeset(MissionForm.new(), %{"mass" => "0", "steps" => []})

    refute changeset.valid?
    assert {"must be greater than %{number}", _} = Keyword.fetch!(changeset.errors, :mass)
    assert {"should have at least %{count} item(s)", _} = Keyword.fetch!(changeset.errors, :steps)
  end

  test "rejects mass above the supported upper limit" do
    changeset =
      MissionForm.changeset(MissionForm.new(), %{
        "mass" => Integer.to_string(MissionForm.max_mass() + 1),
        "steps" => [%{"action" => "launch", "planet" => "Earth"}]
      })

    refute changeset.valid?
    assert {"must be less than or equal to %{number}", _} = Keyword.fetch!(changeset.errors, :mass)
  end

  test "rejects non-integer mass input" do
    for invalid_mass <- ["abc", "12.5"] do
      changeset =
        MissionForm.changeset(MissionForm.new(), %{
          "mass" => invalid_mass,
          "steps" => [%{"action" => "launch", "planet" => "Earth"}]
        })

      refute changeset.valid?
      assert {"is invalid", _} = Keyword.fetch!(changeset.errors, :mass)
    end
  end

  test "requires mass and steps when params are missing" do
    changeset = MissionForm.changeset(%MissionForm{}, %{})

    refute changeset.valid?
    assert {"can't be blank", _} = Keyword.fetch!(changeset.errors, :mass)
    assert {"can't be blank", _} = Keyword.fetch!(changeset.errors, :steps)
  end

  test "builds a default mission form with one launch step" do
    assert %MissionForm{
             mass: nil,
             steps: [%MissionStep{action: "launch", planet: "Earth"}]
           } = MissionForm.new()
  end

  test "accepts valid mission params and converts them to mission input" do
    params = %{
      "mass" => "28801",
      "steps" => [
        %{"action" => "launch", "planet" => "Earth"},
        %{"action" => "land", "planet" => "Moon"},
        %{"action" => "launch", "planet" => "Moon"},
        %{"action" => "land", "planet" => "Earth"}
      ]
    }

    changeset = MissionForm.changeset(MissionForm.new(), params)

    assert changeset.valid?

    mission =
      changeset
      |> Ecto.Changeset.apply_action!(:validate)
      |> MissionForm.to_mission()

    assert mission == %{
             mass: 28_801,
             steps: [
               %{action: "launch", planet: "Earth"},
               %{action: "land", planet: "Moon"},
               %{action: "launch", planet: "Moon"},
               %{action: "land", planet: "Earth"}
             ]
           }
  end

  test "rejects invalid step attributes" do
    params = %{
      "mass" => "1000",
      "steps" => [%{"action" => "dock", "planet" => "Venus"}]
    }

    changeset = MissionForm.changeset(MissionForm.new(), params)

    refute changeset.valid?

    step_changeset = Enum.find(changeset.changes.steps, &match?(%Ecto.Changeset{valid?: false}, &1))

    assert step_changeset
    assert {"is invalid", _} = Keyword.fetch!(step_changeset.errors, :action)
    assert {"is invalid", _} = Keyword.fetch!(step_changeset.errors, :planet)
  end

  test "rejects duplicate action and planet combinations" do
    params = %{
      "mass" => "1000",
      "steps" => [
        %{"action" => "launch", "planet" => "Earth"},
        %{"action" => "launch", "planet" => "Earth"}
      ]
    }

    changeset = MissionForm.changeset(MissionForm.new(), params)

    refute changeset.valid?

    assert {"must not contain duplicate action and planet combinations", _} =
             Keyword.fetch!(changeset.errors, :steps)
  end
end
