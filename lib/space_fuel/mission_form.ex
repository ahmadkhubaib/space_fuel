defmodule SpaceFuel.MissionForm do
  use Ecto.Schema
  import Ecto.Changeset

  alias SpaceFuel.Fuel
  alias SpaceFuel.MissionStep

  @max_mass 1_000_000

  @primary_key false
  embedded_schema do
    field :mass, :integer
    embeds_many :steps, MissionStep, on_replace: :delete
  end

  def max_mass, do: @max_mass

  def new do
    %__MODULE__{steps: [%MissionStep{action: "launch", planet: "Earth"}]}
  end

  def changeset(form, attrs) do
    form
    |> cast(attrs, [:mass])
    |> validate_required([:mass])
    |> validate_number(:mass, greater_than: 0, less_than_or_equal_to: @max_mass)
    |> cast_embed(:steps, required: true, with: &MissionStep.changeset/2)
    |> validate_length(:steps, min: 1)
    |> validate_unique_step_combinations()
  end

  defp validate_unique_step_combinations(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  defp validate_unique_step_combinations(changeset) do
    steps = Ecto.Changeset.get_field(changeset, :steps, [])

    case Fuel.validate_mission_steps(steps) do
      :ok -> changeset
      {:error, message} -> add_error(changeset, :steps, message)
    end
  end

  def to_mission(%__MODULE__{mass: mass, steps: steps}) do
    %{mass: mass, steps: Enum.map(steps, &%{action: &1.action, planet: &1.planet})}
  end
end
