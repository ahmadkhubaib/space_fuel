defmodule SpaceFuel.MissionStep do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :action, :string
    field :planet, :string
  end

  @actions ~w(launch land)
  @planets ~w(Earth Moon Mars)

  def actions, do: @actions
  def planets, do: @planets

  def changeset(step, attrs) do
    step
    |> cast(attrs, [:action, :planet])
    |> validate_required([:action, :planet])
    |> validate_inclusion(:action, @actions)
    |> validate_inclusion(:planet, @planets)
  end
end
