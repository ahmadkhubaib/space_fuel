defmodule SpaceFuelWeb.MissionComponents do
  use SpaceFuelWeb, :html

  attr :tone, :atom, values: [:error, :warning, :success], required: true
  attr :title, :string, required: true
  attr :message, :string, required: true
  attr :id, :string, default: nil
  attr :class, :string, default: nil
  attr :icon_class, :string, default: "size-5 shrink-0"
  def status_alert(assigns) do
    {icon_name, alert_class, message_class} =
      case assigns.tone do
        :error ->
          {"hero-exclamation-triangle", "alert-error border border-rose-200 bg-rose-50 text-rose-900", "text-rose-800"}

        :warning ->
          {"hero-exclamation-triangle", "alert-warning border border-amber-200 bg-amber-50 text-amber-900", "text-amber-800"}

        :success ->
          {"hero-check-circle", "alert-success border border-emerald-200 bg-emerald-50 text-emerald-900", "text-emerald-800"}
      end

    assigns =
      assigns
      |> assign(:icon_name, icon_name)
      |> assign(:alert_class, alert_class)
      |> assign(:message_class, message_class)

    ~H"""
    <div id={@id} class={["alert rounded-2xl shadow-sm", @alert_class, @class]}>
      <.icon name={@icon_name} class={@icon_class} />
      <div>
        <div class="text-sm font-semibold">{@title}</div>
        <div class={["mt-1 text-sm leading-6", @message_class]}>{@message}</div>
      </div>
    </div>
    """
  end

  attr :form, :any, required: true
  attr :result, :any, required: true
  attr :duplicate_indexes, :any, default: MapSet.new()
  def builder_errors(assigns)

  attr :idx, :integer, required: true
  attr :step, :map, required: true
  attr :steps_count, :integer, required: true
  attr :action_options, :list, required: true
  attr :planet_options, :list, required: true
  attr :duplicate_indexes, :any, default: MapSet.new()
  def step_row(assigns)

  attr :result, :any, required: true
  def summary_status(assigns)

  embed_templates "mission_components/*"
end
