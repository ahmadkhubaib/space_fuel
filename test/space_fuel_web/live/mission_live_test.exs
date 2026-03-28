defmodule SpaceFuelWeb.MissionLiveTest do
  use SpaceFuelWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  test "summary status switches when the mission becomes valid", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert has_element?(view, "#mission-summary-status", "Fix the errors in Mission Builder")

    render_change(view, "validate", %{
      "mission_form" => %{
        "mass" => "1000",
        "steps" => %{
          "0" => %{"action" => "launch", "planet" => "Earth"}
        }
      }
    })

    assert has_element?(view, "#mission-summary-status", "Mission valid")
  end

  test "duplicate step errors suppress the empty mass banner", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    view
    |> element("#add-step-button")
    |> render_click()

    render_change(view, "validate", %{
      "mission_form" => %{
        "mass" => "",
        "steps" => %{
          "0" => %{"action" => "launch", "planet" => "Earth"},
          "1" => %{"action" => "launch", "planet" => "Earth"}
        }
      }
    })

    assert has_element?(view, "#mission-summary-status", "Fix the errors in Mission Builder")
    assert has_element?(view, "#duplicate-step-alert-0")
    assert has_element?(view, "#duplicate-step-alert-1")
    refute has_element?(view, "#empty-mass-alert")
  end

  test "incomplete duplicate candidates do not show duplicate warnings", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    view
    |> element("#add-step-button")
    |> render_click()

    render_change(view, "validate", %{
      "mission_form" => %{
        "mass" => "",
        "steps" => %{
          "0" => %{"action" => "launch", "planet" => "Earth"},
          "1" => %{"planet" => "Earth"}
        }
      }
    })

    refute has_element?(view, "#duplicate-step-alert-0")
    refute has_element?(view, "#duplicate-step-alert-1")
  end

  test "add and remove step controls update the builder", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    assert has_element?(view, "#mission_form_steps_0_action")
    refute has_element?(view, "#mission_form_steps_1_action")

    view
    |> element("#add-step-button")
    |> render_click()

    assert has_element?(view, "#mission_form_steps_1_action")

    view
    |> element("#remove-step-button-1")
    |> render_click()

    assert has_element?(view, "#mission_form_steps_0_action")
    refute has_element?(view, "#mission_form_steps_1_action")
  end
end
