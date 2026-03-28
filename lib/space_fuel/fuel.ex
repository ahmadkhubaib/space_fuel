defmodule SpaceFuel.Fuel do
  @moduledoc """
  Pure fuel calculation logic for mission planning.

  The calculator uses the following formulas (all masses in kilograms):

  - Launch: `floor(mass * gravity * 0.042 - 33)`
  - Landing: `floor(mass * gravity * 0.033 - 42)`

  The returned fuel for a step includes the recursive "fuel for the fuel" accumulation
  — additional fuel required to carry the fuel itself — summed until the additional
  amount is 0 or negative.

  Example (landing Apollo 11 CSM on Earth):

      iex> SpaceFuel.Fuel.step_breakdown(28801, "land", "Earth")
      [9278, 2960, 915, 254, 40]

      iex> SpaceFuel.Fuel.step_fuel(28801, "land", "Earth")
      13447

  Use `mission_total/2` to compute a full flight path total.
  """

  @gravity %{
    "Earth" => 9.807,
    "Moon" => 1.62,
    "Mars" => 3.711
  }
  @launch_multiplier 0.042
  @launch_offset 33
  @landing_multiplier 0.033
  @landing_offset 42
  @duplicate_steps_error "must not contain duplicate action and planet combinations"

  @spec gravities() :: map()
  def gravities, do: @gravity

  @spec gravity_for(String.t()) :: {:ok, float()} | :error
  @doc "Return gravity for a planet without raising (returns `{:ok, g}` or `:error`)."
  def gravity_for(planet), do: Map.fetch(@gravity, planet)

  @spec gravity_for!(String.t()) :: float()
  @doc "Return gravity for a planet or raise if unknown."
  def gravity_for!(planet), do: Map.fetch!(@gravity, planet)

  @spec step_fuel(pos_integer(), String.t(), String.t()) :: non_neg_integer()
  @doc "Compute total fuel required for a single action (including recursive fuel-for-fuel)."
  def step_fuel(mass, action, planet) when is_integer(mass) and mass > 0 do
    mass
    |> base_fuel(action, planet)
    |> accumulate_recursive(action, planet, 0)
  end

  @spec step_breakdown(pos_integer(), String.t(), String.t()) :: [non_neg_integer()]
  @doc "Return the list of per-iteration fuel amounts for a single step (most significant first)."
  def step_breakdown(mass, action, planet) when is_integer(mass) and mass > 0 do
    do_step_breakdown(mass, action, planet, [])
  end

  @spec validate_mission_steps(list(map())) :: :ok | {:error, String.t()}
  @doc "Validate mission steps before running a calculation."
  def validate_mission_steps(steps) when is_list(steps) do
    duplicates? =
      steps
      |> Enum.group_by(&step_combo/1)
      |> Enum.any?(fn
        {{nil, _}, _group} -> false
        {{_, nil}, _group} -> false
        {_combo, group} -> length(group) > 1
      end)

    if duplicates? do
      {:error, @duplicate_steps_error}
    else
      :ok
    end
  end

  defp do_step_breakdown(mass, action, planet, acc) do
    fuel = base_fuel(mass, action, planet)

    if fuel <= 0 do
      Enum.reverse(acc)
    else
      do_step_breakdown(fuel, action, planet, [fuel | acc])
    end
  end

  @spec mission_total(pos_integer(), list(map())) :: %{total_fuel: non_neg_integer(), breakdown: list(map())}
  @doc """
  Compute total fuel for a mission path. Returns `%{total_fuel: integer, breakdown: [%{action, planet, effective_mass, fuel}]}`.

  Note: `effective_mass` is the equipment mass plus accumulated fuel from later steps.
  """
  def mission_total(mass, steps) when is_integer(mass) and mass > 0 and is_list(steps) do
    case validate_mission_steps(steps) do
      :ok -> :ok
      {:error, message} -> raise ArgumentError, message
    end

    {total, breakdown} =
      steps
      |> Enum.reverse()
      |> Enum.reduce({0, []}, fn step, {acc_fuel, acc_breakdown} ->
        effective_mass = mass + acc_fuel
        fuel = step_fuel(effective_mass, step.action, step.planet)

        detail = %{
          action: step.action,
          planet: step.planet,
          effective_mass: effective_mass,
          fuel: fuel
        }

        {acc_fuel + fuel, [detail | acc_breakdown]}
      end)

    %{total_fuel: total, breakdown: breakdown}
  end

  defp step_combo(step), do: {Map.get(step, :action), Map.get(step, :planet)}

  defp accumulate_recursive(next_fuel, _action, _planet, total) when next_fuel <= 0, do: total

  defp accumulate_recursive(next_fuel, action, planet, total) do
    additional = base_fuel(next_fuel, action, planet)
    accumulate_recursive(additional, action, planet, total + next_fuel)
  end

  defp base_fuel(mass, "launch", planet) do
    floor(mass * gravity_for!(planet) * @launch_multiplier - @launch_offset)
  end

  defp base_fuel(mass, "land", planet) do
    floor(mass * gravity_for!(planet) * @landing_multiplier - @landing_offset)
  end
end
