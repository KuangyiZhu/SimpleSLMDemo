import json
from pathlib import Path
from typing import Any

from petrinet_action import PetriNetAction
from petrinet_condition import PetriNetCondition
from petrinet_memory_storage import PetriNetMemoryStorage


class PetriNetConnectionParser:
    """Parse a connection JSON file and connect existing Petri-net objects."""

    def __init__(self, storage: PetriNetMemoryStorage) -> None:
        if not isinstance(storage, PetriNetMemoryStorage):
            raise TypeError("storage must be a PetriNetMemoryStorage")
        self._storage = storage

    def get_storage(self) -> PetriNetMemoryStorage:
        return self._storage

    def parse(self, file_path: str | Path) -> None:
        with Path(file_path).open(encoding="utf-8") as json_file:
            data: Any = json.load(json_file)

        condition_connections, action_connections = self._validate_json(data)
        conditions = self._storage.get_conditions()
        actions = self._storage.get_actions()

        # Validation is complete, so replacing the current connections is safe.
        for condition in conditions.values():
            condition.get_actions().clear()
        for action in actions.values():
            action.get_conditions().clear()

        for condition_name, action_names in condition_connections:
            condition = conditions[condition_name]
            for action_name in action_names:
                condition.get_actions()[action_name] = actions[action_name]

        for action_name, condition_names in action_connections:
            action = actions[action_name]
            for condition_name in condition_names:
                action.get_conditions()[condition_name] = conditions[condition_name]

    def _validate_json(
        self,
        data: Any,
    ) -> tuple[list[tuple[str, list[str]]], list[tuple[str, list[str]]]]:
        if not isinstance(data, dict):
            raise ValueError("the JSON root must be an object")

        if "condition_connections" not in data:
            raise ValueError("missing condition_connections")
        if "action_connections" not in data:
            raise ValueError("missing action_connections")

        conditions = self._storage.get_conditions()
        actions = self._storage.get_actions()

        condition_connections = self._validate_connections(
            entries=data["condition_connections"],
            source_field="condition",
            target_field="actions",
            known_sources=conditions,
            known_targets=actions,
        )
        action_connections = self._validate_connections(
            entries=data["action_connections"],
            source_field="action",
            target_field="conditions",
            known_sources=actions,
            known_targets=conditions,
        )
        return condition_connections, action_connections

    @staticmethod
    def _validate_connections(
        entries: Any,
        source_field: str,
        target_field: str,
        known_sources: dict[str, Any],
        known_targets: dict[str, Any],
    ) -> list[tuple[str, list[str]]]:
        if not isinstance(entries, list):
            raise ValueError(f"{source_field}_connections must be an array")

        validated: list[tuple[str, list[str]]] = []
        seen_sources: set[str] = set()

        for index, entry in enumerate(entries):
            location = f"{source_field}_connections[{index}]"
            if not isinstance(entry, dict):
                raise ValueError(f"{location} must be an object")

            source_name = entry.get(source_field)
            target_names = entry.get(target_field)

            if not isinstance(source_name, str):
                raise ValueError(f"{location}.{source_field} must be a string")
            if source_name not in known_sources:
                raise ValueError(f"unknown {source_field}: {source_name}")
            if source_name in seen_sources:
                raise ValueError(f"duplicate {source_field}: {source_name}")
            seen_sources.add(source_name)

            if not isinstance(target_names, list):
                raise ValueError(f"{location}.{target_field} must be an array")

            seen_targets: set[str] = set()
            for target_name in target_names:
                if not isinstance(target_name, str):
                    raise ValueError(
                        f"every value in {location}.{target_field} must be a string"
                    )
                if target_name not in known_targets:
                    singular_target = target_field.removesuffix("s")
                    raise ValueError(f"unknown {singular_target}: {target_name}")
                if target_name in seen_targets:
                    raise ValueError(
                        f"duplicate {target_field} value for {source_name}: "
                        f"{target_name}"
                    )
                seen_targets.add(target_name)

            validated.append((source_name, target_names.copy()))

        return validated
