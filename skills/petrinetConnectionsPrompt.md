# Prompt for `petrinet_connections.json`

Use the following prompt to generate a Petri-net connection file.

## Prompt

Generate a JSON document named `petrinet_connections.json` that describes directional connections between existing Petri-net conditions and actions.

The document must use exactly this root structure:

```json
{
  "condition_connections": [],
  "action_connections": []
}
```

Use `condition_connections` to describe which actions are connected from each condition:

```json
{
  "condition": "condition_name",
  "actions": [
    "action_name_1",
    "action_name_2"
  ]
}
```

Use `action_connections` to describe which conditions are connected from each action:

```json
{
  "action": "action_name",
  "conditions": [
    "condition_name_1",
    "condition_name_2"
  ]
}
```

Follow these rules:

1. Output valid JSON only when producing the final JSON file.
2. Use only condition and action names provided by the user.
3. Do not define token counts, consuming times, callbacks, or other object properties.
4. Treat every connection as directional.
5. Do not automatically add reverse connections.
6. Declare each source condition only once in `condition_connections`.
7. Declare each source action only once in `action_connections`.
8. Do not repeat a target name within the same `actions` or `conditions` array.
9. Preserve the requested action order because the first action is selected first by the current implementation.
10. Use an empty array when a source has no outgoing connections.

The meaning of the two directions is:

```text
condition -> action
```

The action is available from that condition.

```text
action -> condition
```

That condition receives a token after the action callback is invoked.

Before generating the JSON, use the following input lists and connection requirements:

```text
Available conditions:
- <condition names>

Available actions:
- <action names>

Required condition-to-action connections:
- <condition> -> <action or actions>

Required action-to-condition connections:
- <action> -> <condition or conditions>
```

## Example output

```json
{
  "condition_connections": [
    {
      "condition": "ready",
      "actions": [
        "start",
        "cancel"
      ]
    },
    {
      "condition": "finished",
      "actions": []
    }
  ],
  "action_connections": [
    {
      "action": "start",
      "conditions": [
        "finished"
      ]
    },
    {
      "action": "cancel",
      "conditions": [
        "finished"
      ]
    }
  ]
}
```

This format describes connections only. All referenced conditions and actions must already exist in the parser's storage before the file is parsed.
