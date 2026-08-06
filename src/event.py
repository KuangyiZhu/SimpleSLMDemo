from collections.abc import Callable
from typing import Any


class Event:
    """An event with a Unix timestamp, name, and optional callback."""

    def __init__(
        self,
        name: str,
        eventtime: int,
        callback: Callable[..., Any] | None = None,
    ) -> None:
        self.set_name(name)
        self.set_eventtime(eventtime)
        self.set_callback(callback)

    def get_eventtime(self) -> int:
        return self._eventtime

    def set_eventtime(self, eventtime: int) -> None:
        if not isinstance(eventtime, int) or isinstance(eventtime, bool):
            raise TypeError("eventtime must be an integer Unix timestamp")
        self._eventtime = eventtime

    def get_name(self) -> str:
        return self._name

    def set_name(self, name: str) -> None:
        if not isinstance(name, str):
            raise TypeError("name must be a string")
        self._name = name

    def set_callback(self, callback: Callable[..., Any] | None) -> None:
        if callback is not None and not callable(callback):
            raise TypeError("callback must be callable or None")
        self._callback = callback

    def invoke_callback(self, *args: Any, **kwargs: Any) -> Any:
        if self._callback is None:
            raise RuntimeError("no callback has been set")
        return self._callback(*args, **kwargs)
