---
name: md-manufacturing-to-mysql
description: Convert manufacturing or production-planning Markdown tables into an executable MySQL 8 SQL schema and seed-data script. Use when a Markdown file describes products/materials, BOMs, routings, work centers/machines, capacities, inventory, production versions, production orders, order operations, machine status, or similar ERP/APS data and the user wants CREATE TABLE, INSERT, indexes, keys, or a MySQL import script.
---

# Goal

Convert a manufacturing-data Markdown file into a clean, executable MySQL 8.0+ SQL file suitable for ERP/APS prototypes, Python data access, OR-Tools, or CP-SAT.

The input Markdown may contain tables plus explanatory prose. Preserve the supplied business data. Infer relational structure only where the relationships are clear.

# Inputs

The user should provide:
- a Markdown file path
- optionally an output `.sql` path
- optionally a database name

Default input file:
`discrete_manufacturing_sample_data.md`

If the user does not specify an input Markdown file, look for and use `discrete_manufacturing_sample_data.md` in the current project or project root.

If the output path is omitted, write:

`<input-stem>_mysql.sql`

If the database name is omitted:
1. infer a short snake_case name from the input filename or document title;
2. prefer `manufacturing_demo` for generic manufacturing examples.

# Workflow

1. Read the full Markdown input.
2. Identify datasets and classify them as:
   - master data
   - transactional/runtime data
   - derived/reporting data
3. Build a normalized relational model.
4. Generate MySQL 8.0+ DDL.
5. Generate seed `INSERT` statements for all concrete rows present in the Markdown.
6. Add practical primary keys, foreign keys, unique constraints, and indexes.
7. Add useful consistency checks where they do not alter business meaning.
8. Add a small section of useful read-only `SELECT` queries for inspection and APS/CP-SAT integration.
9. Write the final SQL file to the requested or inferred output path.
10. Report the output path and summarize any assumptions or inconsistencies found in the source Markdown.

# Manufacturing modeling rules

Use these conventions unless the input explicitly specifies a different model.

## Material

Represent finished products, semi-finished products, and raw materials in one `material` table.

Typical material types:
- `FERT`: finished product
- `HALB`: semi-finished product
- `ROH`: raw material

Do not split products and raw materials into separate tables unless the source explicitly requires it.

## BOM

Use:
- `bom_header`
- `bom_item`

A BOM describes **what components/materials are consumed by a product**.

Do not place machines or work centers in the BOM.

Typical relationship:

`material (product) -> bom_header -> bom_item -> material (component)`

Keep quantities numeric and retain the source unit.

## Routing

Use:
- `routing_header`
- `routing_operation`

A Routing describes **how a product is produced**.

Each routing operation may contain:
- operation number / sequence
- operation name
- work center
- setup time
- processing time
- wait time
- move time

Typical relationship:

`material (product) -> routing_header -> routing_operation -> work_center`

Routing is master data. It does not contain the dynamic scheduling algorithm.

## Work Center and Capacity

Use:
- `work_center`
- `work_center_capacity`

A work center may represent:
- a machine
- a production line
- a labor pool
- a tool/resource group

Do not assume every work center is a single physical machine.

Capacity data should be time-phased when the Markdown contains dates, shifts, calendars, maintenance windows, or available minutes.

## Production Version

When the Markdown associates one product with a BOM and a Routing, use a `production_version` table:

`product -> production_version -> bom + routing`

Support validity dates and lot-size bounds if present.

## Inventory

Use an `inventory` table with fields such as:
- material
- plant
- storage location
- quantity
- unit
- reserved quantity if present

## Production Order

Use:
- `production_order`
- `production_order_operation`

A production order is transactional/runtime data.

When operation rows are provided or can be unambiguously instantiated from a routing, `production_order_operation` should hold order-specific operation data such as:
- work center
- quantity
- setup time
- processing time
- planned start/end
- actual start/end
- status

Do not invent actual execution timestamps.

## Machine / Work-Center Status

Use a time-stamped `machine_status` table when the source contains:
- RUNNING
- IDLE
- SETUP
- BREAKDOWN
- MAINTENANCE
- OFFLINE
- other resource availability events

# SQL design rules

- Target MySQL 8.0+.
- Use `utf8mb4`.
- Prefer `InnoDB`.
- Use `BIGINT` for numeric identifiers when appropriate.
- Use `DECIMAL` rather than floating point for exact quantities, rates, and processing values.
- Use `DATE`, `TIME`, and `DATETIME` appropriately.
- Use foreign keys for clear parent-child relationships.
- Add indexes for common joins and resource-conflict queries.
- Add `UNIQUE` constraints for stable business codes when appropriate.
- Add `CHECK` constraints only for obvious invariants such as:
  - quantity > 0
  - valid_to >= valid_from
  - priority >= 1
  - utilization within a valid range
- Avoid overusing `ENUM` if the source appears extensible. For a small demo dataset, `ENUM` is acceptable for stable status/type fields.
- Preserve non-ASCII descriptions with `utf8mb4`.
- Use `NULL` for missing runtime values rather than inventing data.
- Keep DDL before inserts.
- Order table creation so referenced parent tables exist first.
- If cleanup statements are included, drop tables in reverse dependency order.
- Do not include destructive operations such as `DROP DATABASE` unless explicitly requested.

# Data fidelity

Never silently change source:
- quantities
- units
- dates
- IDs
- product codes
- component codes
- operation numbers
- processing times
- order quantities
- priorities
- statuses

If the Markdown is inconsistent:
- preserve the source where possible
- add a SQL comment describing the inconsistency
- mention it in the final response

If a value must be inferred to make the schema executable:
- make the smallest reasonable inference
- document the assumption

# Useful queries to include

When applicable, append read-only sample queries for:

1. BOM explosion for one product.
2. Routing lookup for one product.
3. Products competing for the same raw material.
4. Products competing for the same work center.
5. Material requirements for released or in-process production orders.
6. Required material versus current inventory.
7. Estimated operation duration:

   `setup + quantity * process_time`

8. Latest machine/work-center status.

Do not add destructive example queries.

# Core semantic distinctions

Keep these concepts separate:

- **Material** = what the item is
- **BOM** = what materials/components it consumes
- **Routing** = how it is produced
- **Work Center** = where/by which capacity resource an operation is performed
- **Production Version** = which BOM + Routing combination is used
- **Production Order** = one concrete production instance
- **Scheduler / CP-SAT** = when operations should run

The scheduling algorithm is not stored inside the Routing.

# Typical resource-conflict interpretation

## Material competition

Two products compete for material when their BOMs contain the same constrained component.

## Capacity competition

Two products compete for machine/resource capacity when their routings contain operations assigned to the same constrained work center.

## Dedicated resources

If only one product uses a component or work center, it is not a direct cross-product competition for that resource.

# CP-SAT-oriented fields worth retaining

When present in the source, preserve:

- order release time
- due time
- priority
- operation sequence
- setup duration
- processing duration per unit
- work-center assignment
- resource capacity
- shift/calendar availability
- inventory quantity
- BOM usage quantity
- machine breakdown windows
- maintenance windows
- planned/actual execution timestamps

Avoid collapsing these into generic text fields.

# Output quality bar

The final `.sql` file should normally be directly usable with:

`mysql -u root -p < output.sql`

unless the user explicitly asks for only a SQL fragment.

When the task requests a file, write the SQL file to disk rather than only printing SQL in the conversation.

# Chat output behavior

After generating the SQL file:

- Do not print the full generated SQL in chat unless the user explicitly asks to see it.
- Always write the generated SQL to a `.sql` file.
- In chat, report only:
  1. the generated file path,
  2. a short summary of what the file contains,
  3. an example command showing how to execute the SQL file.
- Do not execute the SQL automatically unless the user explicitly asks.

Use an execution example such as:

`mysql -u root -p < <output.sql>`

For example:

`mysql -u root -p < sql/manufacturing_demo_mysql.sql`

If the generated SQL does not create/select a database itself, explain that the target database must be created or specified first.
