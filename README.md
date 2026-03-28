# SpaceFuel

Interplanetary fuel calculator built with Elixir and Phoenix LiveView.

## Run

1. Install dependencies:
   `mix setup`
2. Start the app:
   `mix phx.server`
3. Open:
   `http://localhost:4000`

## Test

Run:
`mix test`

## Future Improvement

If this project grows, `Commanded` could be used to model mission changes as commands and events.
That would help if you later want audit history, replayable mission updates, or more complex workflows.
