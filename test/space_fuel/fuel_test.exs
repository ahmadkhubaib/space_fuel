defmodule SpaceFuel.FuelTest do
  use ExUnit.Case, async: true
  doctest SpaceFuel.Fuel

  alias SpaceFuel.Fuel

  test "gravity catalog exposes supported planets" do
    assert Fuel.gravities() == %{
             "Earth" => 9.807,
             "Moon" => 1.62,
             "Mars" => 3.711
           }
  end

  test "landing fuel is recursive" do
    assert Fuel.step_fuel(28_801, "land", "Earth") == 13_447
  end

  test "launch fuel is recursive" do
    assert Fuel.step_fuel(28_801, "launch", "Earth") == 19_772
  end

  test "step breakdown matches example" do
    assert Fuel.step_breakdown(28_801, "land", "Earth") == [9_278, 2_960, 915, 254, 40]
  end

  test "small mass yields no fuel" do
    assert Fuel.step_fuel(10, "land", "Earth") == 0
    assert Fuel.step_breakdown(10, "land", "Earth") == []
  end

  test "gravity helpers" do
    assert Fuel.gravity_for("Earth") == {:ok, 9.807}
    assert Fuel.gravity_for("Venus") == :error
    assert Fuel.gravity_for!("Mars") == 3.711
    assert_raise KeyError, fn -> Fuel.gravity_for!("Pluto") end
  end

  test "validates duplicate mission step combinations" do
    assert Fuel.validate_mission_steps([
             %{action: "launch", planet: "Earth"},
             %{action: "land", planet: "Moon"}
           ]) == :ok

    assert Fuel.validate_mission_steps([
             %{action: "launch", planet: "Earth"},
             %{action: "launch", planet: "Earth"}
           ]) == {:error, "must not contain duplicate action and planet combinations"}
  end

  test "ignores incomplete steps when checking duplicate combinations" do
    assert Fuel.validate_mission_steps([
             %{action: nil, planet: "Earth"},
             %{action: nil, planet: "Earth"},
             %{action: "launch", planet: nil},
             %{action: "launch", planet: nil}
           ]) == :ok
  end

  test "apollo 11 mission total matches challenge example" do
    steps = [
      %{action: "launch", planet: "Earth"},
      %{action: "land", planet: "Moon"},
      %{action: "launch", planet: "Moon"},
      %{action: "land", planet: "Earth"}
    ]

    assert %{total_fuel: 51_898} = Fuel.mission_total(28_801, steps)
  end

  test "mars mission total matches challenge example" do
    steps = [
      %{action: "launch", planet: "Earth"},
      %{action: "land", planet: "Mars"},
      %{action: "launch", planet: "Mars"},
      %{action: "land", planet: "Earth"}
    ]

    assert %{total_fuel: 33_388} = Fuel.mission_total(14_606, steps)
  end

  test "passenger ship mission total matches challenge example" do
    steps = [
      %{action: "launch", planet: "Earth"},
      %{action: "land", planet: "Moon"},
      %{action: "launch", planet: "Moon"},
      %{action: "land", planet: "Mars"},
      %{action: "launch", planet: "Mars"},
      %{action: "land", planet: "Earth"}
    ]

    assert %{total_fuel: 212_161} = Fuel.mission_total(75_432, steps)
  end

  test "mission total returns detailed breakdown per step" do
    steps = [
      %{action: "launch", planet: "Earth"},
      %{action: "land", planet: "Moon"},
      %{action: "launch", planet: "Moon"},
      %{action: "land", planet: "Earth"}
    ]

    assert %{
             total_fuel: 51_898,
             breakdown: [
               %{action: "launch", planet: "Earth", effective_mass: 47_711, fuel: 32_988},
               %{action: "land", planet: "Moon", effective_mass: 45_249, fuel: 2_462},
               %{action: "launch", planet: "Moon", effective_mass: 42_248, fuel: 3_001},
               %{action: "land", planet: "Earth", effective_mass: 28_801, fuel: 13_447}
             ]
           } = Fuel.mission_total(28_801, steps)
  end

  test "mission total handles missions with no steps" do
    assert Fuel.mission_total(28_801, []) == %{total_fuel: 0, breakdown: []}
  end

  test "mission total rejects duplicate mission step combinations" do
    steps = [
      %{action: "launch", planet: "Earth"},
      %{action: "launch", planet: "Earth"}
    ]

    assert_raise ArgumentError, "must not contain duplicate action and planet combinations", fn ->
      Fuel.mission_total(28_801, steps)
    end
  end

  test "step fuel raises for unsupported direct backend input" do
    assert_raise KeyError, fn ->
      Fuel.step_fuel(1_000, "launch", "Venus")
    end

    assert_raise FunctionClauseError, fn ->
      Fuel.step_fuel(1_000, "dock", "Earth")
    end
  end

  test "mission total raises for malformed direct backend step input" do
    assert_raise KeyError, fn ->
      Fuel.mission_total(1_000, [%{action: "launch"}])
    end
  end
end
