# Discrete Event Engine and Petri Net — Handover

## Overview

This project is an early Python prototype containing:

- A discrete-event model (`Event`)
- A timestamp-ordered priority queue (`EventQueue`)
- A Petri-net action model (`PetriNetAction`)
- A Petri-net condition/token model (`PetriNetCondition`)

The project uses Python 3.10+ type-annotation syntax and has no external dependencies.

## Project files

| File | Purpose |
| --- | --- |
| `event.py` | Defines an event with a name, integer Unix timestamp, and callback. |
| `event_queue.py` | Stores events in a min-heap and pops the earliest event. |
| `petrinet_action.py` | Defines an action, its consuming time, callback, and output conditions. |
| `petrinet_condition.py` | Defines a named condition with tokens and an action map. |
| `hello.py` | Runnable demonstration of the event queue. |
| `requirements.txt` | Empty because the prototype uses only the Python standard library. |

## Event

Constructor:

```python
Event(
    name: str,
    eventtime: int,
    callback: Callable[..., Any] | None = None,
)
```

`eventtime` is mandatory and represents whole seconds since the Unix epoch.

Methods:

- `get_eventtime() -> int`
- `set_eventtime(eventtime: int) -> None`
- `get_name() -> str`
- `set_name(name: str) -> None`
- `set_callback(callback) -> None`
- `invoke_callback(*args, **kwargs) -> Any`

Calling `invoke_callback()` without an assigned callback raises `RuntimeError`.

## EventQueue

`EventQueue` uses the standard-library `heapq` min-heap. Each internal entry is:

```python
(event_timestamp, insertion_sequence, event)
```

The timestamp ensures that `pop()` returns the earliest event. The insertion sequence ensures that events with equal timestamps are returned in insertion order.

Methods:

- `push(event: Event) -> None`
- `pop() -> Event`

Popping an empty queue raises `IndexError`.

Important: changing an event's timestamp after pushing it does not update its existing heap priority. Remove and reinsert the event if its scheduled time changes.

## PetriNetAction

Constructor:

```python
PetriNetAction(
    action_name: str,
    consuming_time: int,
    callback: Callable[..., Any] | None = None,
)
```

`action_name` is mandatory. `consuming_time` is a non-negative integer. Each action starts with an empty condition map:

```python
dict[str, PetriNetCondition]
```

Methods:

- `get_action_name() -> str`
- `get_consuming_time() -> int`
- `set_consuming_time(consuming_time: int) -> None`
- `get_callback() -> Callable[..., Any] | None`
- `set_callback(callback) -> None`
- `get_conditions() -> dict[str, PetriNetCondition]`
- `invoke_callback(*args, **kwargs) -> Any`

`invoke_callback()` calls the callback if one exists, then increases every linked condition by one token. It returns the callback result, or `None` when no callback exists. If the callback raises an exception, condition tokens are not increased because execution stops at that exception.

## PetriNetCondition

Constructor:

```python
PetriNetCondition(condition_name: str, tokens: int)
```

The condition name is mandatory. The initial token count must be an integer greater than zero. A condition can later decrease to zero but never below zero.

Each condition starts with an empty action map:

```python
dict[str, PetriNetAction]
```

Methods:

- `increase_token() -> None`
- `decrease_token() -> None`
- `get_actions() -> dict[str, PetriNetAction]`
- `choose_action() -> PetriNetAction`

`choose_action()` returns the first inserted action without removing it. It raises `IndexError` when the action map is empty.

## Connecting actions and conditions

The current API exposes the maps directly through getters:

```python
from petrinet_action import PetriNetAction
from petrinet_condition import PetriNetCondition


def complete_job() -> None:
    print("Job completed")


ready = PetriNetCondition("ready", 1)
finished = PetriNetCondition("finished", 1)
run = PetriNetAction("run", 5, complete_job)

ready.get_actions()[run.get_action_name()] = run
run.get_conditions()[finished.condition_name] = finished

selected_action = ready.choose_action()
ready.decrease_token()
selected_action.invoke_callback()

print(ready.tokens)     # 0
print(finished.tokens)  # 2
```

Dictionary insertion order determines which action `choose_action()` selects.

## Running the demo

From the project directory:

```bash
source .venv/bin/activate
python hello.py
```

The demo creates three events, pushes them in non-chronological order, and shows that the queue pops them from the smallest timestamp to the largest.

## Current limitations and next steps

- There is not yet an engine loop that repeatedly pops and executes events.
- Petri-net actions are not yet automatically converted into scheduled events using `consuming_time`.
- Maps are mutable and exposed directly; invalid keys or values can currently be inserted by callers.
- Conditions require a positive initial token count, so an initially disabled condition with zero tokens cannot yet be constructed.
- No automated test suite has been added; verification currently uses direct Python commands and `hello.py`.
- There is no policy yet for selecting among multiple enabled actions beyond first insertion order.

A natural next implementation step is an engine class that selects an action, consumes the input condition's token, schedules an `Event` at `current_time + consuming_time`, and invokes the action when that event becomes due.
