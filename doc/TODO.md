# TODO

## 1. Decide object identity for parsed connections

The current parser connects objects by retrieving them from the in-memory storage maps:

```python
for condition_name, action_names in condition_connections:
    condition = conditions[condition_name]
    for action_name in action_names:
        condition.get_actions()[action_name] = actions[action_name]

for action_name, condition_names in action_connections:
    action = actions[action_name]
    for condition_name in condition_names:
        action.get_conditions()[condition_name] = conditions[condition_name]
```

### Current behavior

Every connection referring to the same name uses the same Python object instance from `PetriNetMemoryStorage`.

For example, all references to `condition_1` point to:

```python
conditions["condition_1"]
```

Therefore, changing its token count through one connection is visible through every other connection to that condition.

### Future design decision

Decide whether a connection should use:

1. The same shared instance from storage, or
2. A new instance created specifically for that connection.

#### Shared-instance model

Advantages:

- A name identifies one canonical Petri-net node.
- Token changes are visible from every connected action.
- Object identity naturally represents graph-node identity.
- It maps well to database records with stable IDs.

Risks:

- Mutating an object from one part of the graph affects all references.
- Accidental shared state may be difficult to diagnose.
- Running multiple independent simulations would require separate storage or separate runtime state.

#### New-instance-per-connection model

Advantages:

- Each connection can have independent runtime state.
- Mutations on one connection do not affect other connections.

Risks:

- Two objects with the same name may have different token counts or configuration.
- Synchronizing copies may be difficult.
- Object names no longer uniquely identify graph nodes.
- Cycles and database persistence require additional identity rules.

### Questions to resolve

- Does a condition name identify one unique node in a Petri net?
- Should tokens belong to the condition definition, a simulation instance, or an individual connection?
- Can multiple Petri-net simulations run concurrently from the same definitions?
- Should actions and conditions have immutable unique IDs in addition to names?
- When database storage is introduced, should connections store object IDs or copied object data?
- If copies are needed, should the parser clone objects or should a separate runtime/simulation builder do it?

### Suggested direction

Keep one canonical shared instance per condition and action within a single Petri-net runtime. Separate persistent definitions from mutable simulation state if multiple independent runs are required.

Under that model:

- Storage preserves canonical definitions or records.
- A runtime builder creates one object graph for each simulation.
- Connections inside one runtime share node instances.
- Different simulation runtimes never share mutable token state.

Do not change the current parser behavior until this model is confirmed.

## Future items

- Define an abstraction that allows `PetriNetMemoryStorage` to be replaced by database-backed storage.
- Add stable identifiers for conditions and actions if names are allowed to change.
- Add automated tests for shared identity, token updates, cycles, and repeated parsing.
- Decide whether parsing should replace existing connections or merge with them.
- Decide whether exposed action and condition maps should remain directly mutable.
