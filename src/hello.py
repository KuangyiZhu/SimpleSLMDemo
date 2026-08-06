import time

from event import Event
from event_queue import EventQueue
from petrinet_action import PetriNetAction
from petrinet_condition import PetriNetCondition
from petrinet_connection_parser import PetriNetConnectionParser
from petrinet_memory_storage import PetriNetMemoryStorage


def greet(person: str) -> str:
    message = f"Hello, {person}!"
    print(message)
    return message


def main() -> None:
    current_time = int(time.time())
    queue = EventQueue()

    queue.push(Event(name="later", eventtime=current_time + 20))
    queue.push(
        Event(
            name="greeting",
            eventtime=current_time + 10,
            callback=greet,
        )
    )
    queue.push(Event(name="earliest", eventtime=current_time))

    first_event = queue.pop()
    print(
        f"First event: {first_event.get_name()} "
        f"at {first_event.get_eventtime()}"
    )

    greeting_event = queue.pop()
    print(
        f"Second event: {greeting_event.get_name()} "
        f"at {greeting_event.get_eventtime()}"
    )
    greeting_event.invoke_callback("World")

    last_event = queue.pop()
    print(
        f"Last event: {last_event.get_name()} "
        f"at {last_event.get_eventtime()}"
    )

    # The demo objects are currently hard-coded in memory.
    storage = PetriNetMemoryStorage()
    storage.add_condition(PetriNetCondition("ready", 1))
    storage.add_condition(PetriNetCondition("finished", 1))
    storage.add_action(PetriNetAction("start", 5))
    storage.add_action(PetriNetAction("cancel", 0))

    parser = PetriNetConnectionParser(storage)
    parser.parse("../test/petrinet_connections.json")

    ready = storage.get_condition("ready")
    selected_action = ready.choose_action()
    print(f"Selected Petri-net action: {selected_action.get_action_name()}")


if __name__ == "__main__":
    main()
