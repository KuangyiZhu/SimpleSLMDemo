from petrinet_action import PetriNetAction


class PetriNetCondition:
    """A Petri net condition containing tokens and available actions."""

    def __init__(self, condition_name: str, tokens: int) -> None:
        if not isinstance(condition_name, str):
            raise TypeError("condition_name must be a string")
        if not isinstance(tokens, int) or isinstance(tokens, bool):
            raise TypeError("tokens must be an integer")
        if tokens <= 0:
            raise ValueError("tokens must be greater than 0")

        self.condition_name = condition_name
        self.tokens = tokens
        self.actions: dict[str, PetriNetAction] = {}

    def increase_token(self) -> None:
        self.tokens += 1

    def decrease_token(self) -> None:
        if self.tokens == 0:
            raise ValueError("tokens cannot be decreased below 0")
        self.tokens -= 1

    def get_actions(self) -> dict[str, PetriNetAction]:
        return self.actions

    def choose_action(self) -> PetriNetAction:
        if not self.actions:
            raise IndexError("cannot choose an action from an empty action map")
        return next(iter(self.actions.values()))


    def exe_action(self) -> None:
        if not self.actions:
            raise IndexError("cannot choose an action from an empty action map")
        if (self.tokens > 0):
            self.choose_action().invoke_callback()
            self.tokens -= 1