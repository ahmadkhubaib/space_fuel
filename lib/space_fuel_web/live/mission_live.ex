defmodule SpaceFuelWeb.MissionLive do
  use SpaceFuelWeb, :live_view

  alias SpaceFuel.Fuel
  alias SpaceFuel.MissionForm
  alias SpaceFuelWeb.MissionComponents
  alias SpaceFuel.MissionStep

  @impl true
  def mount(_params, _session, socket) do
    action_options = MissionStep.actions() |> Enum.map(&{String.capitalize(&1), &1})
    planet_options = MissionStep.planets() |> Enum.map(&{&1, &1})

    {:ok,
     socket
     |> assign(:page_title, "Interplanetary Fuel Calculator")
     |> assign(:action_options, action_options)
     |> assign(:planet_options, planet_options)
     |> apply_mission_params(%{})}
  end

  @impl true
  def handle_event("validate", %{"mission_form" => params}, socket) do
    {:noreply, apply_mission_params(socket, params)}
  end

  def handle_event("add_step", _params, socket) do
    form_data = socket.assigns.form_data
    steps = form_data["steps"] ++ [%{"action" => "launch", "planet" => "Earth"}]
    params = Map.put(form_data, "steps", steps)

    {:noreply, apply_mission_params(socket, params)}
  end

  def handle_event("remove_step", %{"index" => index}, socket) do
    idx = String.to_integer(index)
    form_data = socket.assigns.form_data

    steps =
      form_data["steps"]
      |> List.delete_at(idx)
      |> case do
        [] -> [%{"action" => "launch", "planet" => "Earth"}]
        steps -> steps
      end

    params = Map.put(form_data, "steps", steps)

    {:noreply, apply_mission_params(socket, params)}
  end

  defp apply_mission_params(socket, params) do
    changeset = build_changeset(params)
    form_data = current_form_data(changeset)
    result = calculate_result(changeset)

    socket
    |> assign(:form_data, form_data)
    |> assign_form_state(changeset, form_data)
    |> assign_duplicate_indexes(changeset)
    |> assign(:result, result)
  end

  defp build_changeset(params) do
    MissionForm.new()
    |> MissionForm.changeset(params)
    |> Map.put(:action, :validate)
  end

  defp assign_form_state(socket, changeset, form_data) do
    assign(
      socket,
      :form,
      to_form(
        form_data,
        as: :mission_form,
        errors: changeset.errors,
        action: changeset.action
      )
    )
  end

  defp assign_duplicate_indexes(socket, changeset) do
    cleaned = Ecto.Changeset.apply_changes(changeset)
    steps = cleaned.steps || []

    duplicate_indexes =
      steps
      |> Enum.with_index()
      |> Enum.group_by(fn {step, _idx} -> {step.action, step.planet} end)
      |> Enum.flat_map(fn
        {{nil, _}, _group} -> []
        {{_, nil}, _group} -> []
        {_combo, [_single]} -> []
        {_combo, group} -> Enum.map(group, fn {_step, idx} -> idx end)
      end)
      |> MapSet.new()

    assign(socket, :duplicate_indexes, duplicate_indexes)
  end

  defp calculate_result(%Ecto.Changeset{valid?: true} = changeset) do
    mission =
      changeset
      |> Ecto.Changeset.apply_action!(:validate)
      |> MissionForm.to_mission()

    Fuel.mission_total(mission.mass, mission.steps)
  end

  defp calculate_result(_), do: nil

  defp current_form_data(changeset) do
    data = Ecto.Changeset.apply_changes(changeset)

    %{
      "mass" => if(is_nil(data.mass), do: "", else: Integer.to_string(data.mass)),
      "steps" =>
        Enum.map(data.steps || [], &%{
          "action" => &1.action || "launch",
          "planet" => &1.planet || "Earth"
        })
    }
  end
end
