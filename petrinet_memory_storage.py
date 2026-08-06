from petrinet_action import PetriNetAction
from petrinet_condition import PetriNetCondition


class PetriNetMemoryStorage:
    """In-memory storage for Petri-net conditions and actions."""

    def __init__(self) -> None:
        self._conditions: dict[str, PetriNetCondition] = {}
        self._actions: dict[str, PetriNetAction] = {}

    def add_condition(self, condition: PetriNetCondition) -> None:
        if not isinstance(condition, PetriNetCondition):
            raise TypeError("condition must be a PetriNetCondition")

        condition_name = condition.condition_name
        if condition_name in self._conditions:
            raise ValueError(f"condition already exists: {condition_name}")
        self._conditions[condition_name] = condition

    def add_action(self, action: PetriNetAction) -> None:
        if not isinstance(action, PetriNetAction):
            raise TypeError("action must be a PetriNetAction")

        action_name = action.get_action_name()
        if action_name in self._actions:
            raise ValueError(f"action already exists: {action_name}")
        self._actions[action_name] = action

    def get_conditions(self) -> dict[str, PetriNetCondition]:
        return self._conditions

    def get_actions(self) -> dict[str, PetriNetAction]:
        return self._actions

    def get_condition(self, condition_name: str) -> PetriNetCondition:
        return self._conditions[condition_name]

    def get_action(self, action_name: str) -> PetriNetAction:
        return self._actions[action_name]
