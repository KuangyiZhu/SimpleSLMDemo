from __future__ import annotations

from collections.abc import Callable
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from petrinet_condition import PetriNetCondition


class PetriNetAction:
    """An action with a consuming time and an optional callback."""

    def __init__(
        self,
        action_name: str,
        consuming_time: int,
        callback: Callable[..., Any] | None = None,
    ) -> None:
        if not isinstance(action_name, str):
            raise TypeError("action_name must be a string")

        self._action_name = action_name
        self.set_consuming_time(consuming_time)
        self.set_callback(callback)
        self._conditions: dict[str, PetriNetCondition] = {}

    def get_action_name(self) -> str:
        return self._action_name

    def get_consuming_time(self) -> int:
        return self._consuming_time

    def set_consuming_time(self, consuming_time: int) -> None:
        if not isinstance(consuming_time, int) or isinstance(consuming_time, bool):
            raise TypeError("consuming_time must be an integer")
        if consuming_time < 0:
            raise ValueError("consuming_time cannot be negative")
        self._consuming_time = consuming_time

    def get_callback(self) -> Callable[..., Any] | None:
        return self._callback

    def set_callback(self, callback: Callable[..., Any] | None) -> None:
        if callback is not None and not callable(callback):
            raise TypeError("callback must be callable or None")
        self._callback = callback

    def invoke_callback(self, *args: Any, **kwargs: Any) -> Any:
        result = None
        if self._callback is not None:
            result = self._callback(*args, **kwargs)

        for condition in self._conditions.values():
            condition.increase_token()

        return result

    def get_conditions(self) -> dict[str, PetriNetCondition]:
        return self._conditions
