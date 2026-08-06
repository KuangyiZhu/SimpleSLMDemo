import heapq
from itertools import count

from event import Event


class EventQueue:
    """A priority queue that returns events in timestamp order."""

    def __init__(self) -> None:
        self._heap: list[tuple[int, int, Event]] = []
        self._sequence = count()

    def push(self, event: Event) -> None:
        if not isinstance(event, Event):
            raise TypeError("event must be an Event")

        heapq.heappush(
            self._heap,
            (event.get_eventtime(), next(self._sequence), event),
        )

    def pop(self) -> Event:
        if not self._heap:
            raise IndexError("pop from an empty EventQueue")

        _, _, event = heapq.heappop(self._heap)
        return event
