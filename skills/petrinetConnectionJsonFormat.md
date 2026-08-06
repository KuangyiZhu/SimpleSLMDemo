# Petri Net Connection JSON Format

## Purpose

This JSON format describes only the connections between existing Petri-net conditions and actions.

It does not define:

- Condition token counts
- Action consuming times
- Action callbacks
- Condition or action objects

Conditions and actions must already exist before the connection file is parsed. The parser uses their names to find and connect them.

## Format

The root JSON object contains two arrays:

```json
{
  "condition_connections": [],
  "action_connections": []
}
```

- `condition_connections` describes connections from conditions to actions.
- `action_connections` describes connections from actions to conditions.

## Complete example

```json
{
  "condition_connections": [
    {
      "condition": "condition_1",
      "actions": [
        "action_1",
        "action_2"
      ]
    },
    {
      "condition": "condition_2",
      "actions": [
        "action_3"
      ]
    }
  ],
  "action_connections": [
    {
      "action": "action_1",
      "conditions": [
        "condition_2",
        "condition_3"
      ]
    },
    {
      "action": "action_2",
      "conditions": [
        "condition_4"
      ]
    }
  ]
}
```

This example represents:

```text
condition_1 -> action_1
condition_1 -> action_2
condition_2 -> action_3

action_1 -> condition_2
action_1 -> condition_3
action_2 -> condition_4
```

## Condition connections

Each item in `condition_connections` has this structure:

```json
{
  "condition": "condition_name",
  "actions": [
    "action_name_1",
    "action_name_2"
  ]
}
```

Fields:

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `condition` | string | Yes | Name of the source condition. |
| `actions` | array of strings | Yes | Names of the actions connected from the condition. |

For every listed action, the parser should create this connection:

```python
condition.get_actions()[action_name] = action
```

The order of names in `actions` is significant because `PetriNetCondition.choose_action()` selects the first action in the action map.

An empty action array is valid:

```json
{
  "condition": "finished",
  "actions": []
}
```

## Action connections

Each item in `action_connections` has this structure:

```json
{
  "action": "action_name",
  "conditions": [
    "condition_name_1",
    "condition_name_2"
  ]
}
```

Fields:

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `action` | string | Yes | Name of the source action. |
| `conditions` | array of strings | Yes | Names of the conditions connected from the action. |

For every listed condition, the parser should create this connection:

```python
action.get_conditions()[condition_name] = condition
```

When `action.invoke_callback()` executes, each connected condition receives one additional token.

An empty condition array is valid:

```json
{
  "action": "terminal_action",
  "conditions": []
}
```

## Parser inputs

Because this file contains only connections, conditions and actions must be registered in the parser's storage before parsing:

```python
storage.add_condition(condition)
storage.add_action(action)
```

`PetriNetMemoryStorage` currently stores the registered objects in two in-memory maps. The parser keeps this storage object as a member variable. The map keys are the names referenced by the JSON file.

## Using the parser

```python
from petrinet_action import PetriNetAction
from petrinet_condition import PetriNetCondition
from petrinet_connection_parser import PetriNetConnectionParser
from petrinet_memory_storage import PetriNetMemoryStorage

ready = PetriNetCondition("ready", 1)
finished = PetriNetCondition("finished", 1)
start = PetriNetAction("start", 5)

storage = PetriNetMemoryStorage()
storage.add_condition(ready)
storage.add_condition(finished)
storage.add_action(start)

parser = PetriNetConnectionParser(storage)
parser.parse("petrinet_connections.json")
```

The storage maps are available through `storage.get_conditions()` and `storage.get_actions()`. The parser's storage is available through `parser.get_storage()`. Parsing replaces all existing connections in the stored objects. It validates the complete document before clearing or creating any connections.

## Validation rules

A parser should reject the file when:

- The root value is not a JSON object.
- `condition_connections` or `action_connections` is missing or is not an array.
- A condition or action name is not a string.
- `actions` or `conditions` is not an array of strings.
- A referenced name does not exist in the corresponding object map.
- The same source name is declared more than once.
- The same target name appears more than once under one source.

Empty connection arrays and empty target arrays are valid.

## Direction of connections

Connections are directional. These two connections have different meanings:

```text
condition_1 -> action_1
action_1 -> condition_1
```

The first connection makes `action_1` available from `condition_1`. The second connection causes `condition_1` to receive a token after `action_1` is invoked.

The parser should not automatically create a reverse connection. Every required direction must be written explicitly in the JSON file.
