#!/usr/bin/env python3
"""
ttl_to_cytoscape.py

Read one or more RDF/Turtle files and generate a self-contained HTML viewer
whose graph data is embedded in the page and rendered by Cytoscape.js.

Requirements:
    pip install rdflib

Usage:
    python ttl_to_cytoscape.py KETTLE-001_process.ttl

    python ttl_to_cytoscape.py \
        KETTLE-001_process.ttl \
        TOASTER-001_process.ttl \
        RICECOOKER-001_process.ttl \
        --out manufacturing_graph.html
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

from rdflib import Graph, URIRef, Literal, BNode, RDF


def short(term) -> str:
    """Human-readable short label for RDF terms."""
    if isinstance(term, URIRef):
        s = str(term)
        if "#" in s:
            return s.rsplit("#", 1)[1]
        return s.rstrip("/").rsplit("/", 1)[-1]

    if isinstance(term, Literal):
        return str(term)

    if isinstance(term, BNode):
        return "_:" + str(term)

    return str(term)


def stable_id(term) -> str:
    raw = f"{type(term).__name__}|{str(term)}".encode("utf-8")
    return "n_" + hashlib.sha1(raw).hexdigest()[:16]


def literal_type(term: Literal) -> str:
    if term.language:
        return f"Literal@{term.language}"
    if term.datatype:
        return "Literal:" + short(term.datatype)
    return "Literal"


def graph_to_elements(g: Graph) -> list[dict]:
    """
    Convert ALL RDF triples into Cytoscape nodes and edges.
    Nothing is filtered.
    """
    rdf_types: dict = {}

    for s, _, o in g.triples((None, RDF.type, None)):
        rdf_types.setdefault(s, []).append(short(o))

    terms = set()

    for s, _, o in g:
        terms.add(s)
        terms.add(o)

    nodes = []

    preferred_types = [
        "Product",
        "Process",
        "ProcessStep",
        "Materials",
        "MaterialUsage",
        "Material",
        "Time",
        "Setup",
        "Processing",
    ]

    for term in sorted(terms, key=lambda x: (type(x).__name__, str(x))):

        if isinstance(term, Literal):
            node_type = literal_type(term)
            label = str(term)
            full = str(term)
            datatype = short(term.datatype) if term.datatype else ""
            language = term.language or ""

        elif isinstance(term, BNode):
            node_type = "BlankNode"
            label = "_:" + str(term)
            full = label
            datatype = ""
            language = ""

        else:
            types = rdf_types.get(term, [])

            node_type = next(
                (t for t in preferred_types if t in types),
                types[0] if types else "Resource"
            )

            label = short(term)
            full = str(term)
            datatype = ""
            language = ""

        nodes.append({
            "data": {
                "id": stable_id(term),
                "label": label,
                "type": node_type,
                "full": full,
                "datatype": datatype,
                "language": language,
                "rdfTypes": rdf_types.get(term, []),
            }
        })

    edges = []

    triples = sorted(
        g,
        key=lambda t: (str(t[0]), str(t[1]), str(t[2]))
    )

    for i, (s, p, o) in enumerate(triples):
        edge_hash = hashlib.sha1(
            (str(s) + str(p) + str(o)).encode("utf-8")
        ).hexdigest()[:12]

        edges.append({
            "data": {
                "id": f"e_{i}_{edge_hash}",
                "source": stable_id(s),
                "target": stable_id(o),
                "label": short(p),
                "predicate": str(p),
            }
        })

    return nodes + edges


def generate_html(datasets: dict[str, list[dict]],
                  triple_counts: dict[str, int]) -> str:

    datasets_json = json.dumps(
        datasets,
        ensure_ascii=False,
        separators=(",", ":")
    )

    counts_json = json.dumps(
        triple_counts,
        ensure_ascii=False
    )

    options = "\n".join(
        f'<option value="{name}">{name}</option>'
        for name in datasets
    )

    default_dataset = next(iter(datasets))

    return f"""<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>TTL Cytoscape Viewer</title>

<script src="https://cdn.jsdelivr.net/npm/cytoscape@3.30.4/dist/cytoscape.min.js"></script>

<style>
* {{
    box-sizing: border-box;
}}

body {{
    margin: 0;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    background: #f7f8fa;
    color: #17202a;
}}

.toolbar {{
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
    align-items: center;
    padding: 12px;
    background: white;
    border-bottom: 1px solid #d9dde3;
}}

select, button {{
    min-height: 36px;
    padding: 0 10px;
    border: 1px solid #cfd5dd;
    border-radius: 8px;
    background: white;
}}

button {{
    cursor: pointer;
}}

.status {{
    margin-left: auto;
    color: #667085;
    font-size: 13px;
}}

.main {{
    display: grid;
    grid-template-columns: minmax(0, 1fr) 330px;
}}

#cy {{
    min-height: 800px;
    background: white;
}}

.details {{
    padding: 16px;
    border-left: 1px solid #d9dde3;
    background: white;
    overflow: auto;
}}

.details h3 {{
    margin-top: 0;
}}

.k {{
    margin-top: 12px;
    color: #667085;
    font-size: 12px;
}}

.v {{
    font-size: 13px;
    word-break: break-all;
    white-space: pre-wrap;
}}

@media (max-width: 900px) {{
    .main {{
        grid-template-columns: 1fr;
    }}

    .details {{
        border-left: 0;
        border-top: 1px solid #d9dde3;
    }}

    #cy {{
        min-height: 650px;
    }}

    .status {{
        width: 100%;
        margin-left: 0;
    }}
}}
</style>
</head>

<body>

<div class="toolbar">

<label>
Dataset
<select id="dataset">
{options}
</select>
</label>

<label>
Layout
<select id="layout">
<option value="breadthfirst">Breadth-first</option>
<option value="cose">CoSE</option>
<option value="circle">Circle</option>
<option value="grid">Grid</option>
</select>
</label>

<label>
Edge labels
<select id="edgeLabel">
<option value="show">Show</option>
<option value="hide">Hide</option>
</select>
</label>

<button id="fit">Fit</button>
<button id="reset">Reset layout</button>

<div class="status" id="status"></div>

</div>

<div class="main">

<div id="cy"></div>

<div class="details">

<h3>Node / Edge details</h3>

<div id="detailsText">
点击节点或边查看 RDF 信息。
</div>

</div>

</div>

<script>

const DATASETS = {datasets_json};
const TRIPLE_COUNTS = {counts_json};

const datasetSelect = document.getElementById("dataset");
const layoutSelect = document.getElementById("layout");
const edgeLabelSelect = document.getElementById("edgeLabel");
const detailsText = document.getElementById("detailsText");
const status = document.getElementById("status");

datasetSelect.value = "{default_dataset}";

const cy = cytoscape({{
    container: document.getElementById("cy"),

    elements: DATASETS["{default_dataset}"],

    style: [

        {{
            selector: "node",
            style: {{
                "label": "data(label)",
                "text-wrap": "wrap",
                "text-max-width": 110,
                "font-size": 10,
                "text-valign": "center",
                "text-halign": "center",
                "background-color": "#cbd5e1",
                "border-width": 1,
                "border-color": "#94a3b8",
                "width": 75,
                "height": 48
            }}
        }},

        {{
            selector: 'node[type="Product"]',
            style: {{
                "shape": "round-rectangle",
                "background-color": "#bfdbfe",
                "width": 110,
                "height": 56,
                "font-weight": "bold"
            }}
        }},

        {{
            selector: 'node[type="Process"]',
            style: {{
                "shape": "round-rectangle",
                "background-color": "#e0e7ff",
                "width": 125
            }}
        }},

        {{
            selector: 'node[type="ProcessStep"]',
            style: {{
                "shape": "round-rectangle",
                "background-color": "#dbeafe",
                "width": 125,
                "height": 58,
                "font-weight": "bold"
            }}
        }},

        {{
            selector: 'node[type="Material"]',
            style: {{
                "shape": "ellipse",
                "background-color": "#dcfce7",
                "width": 95
            }}
        }},

        {{
            selector: 'node[type="MaterialUsage"]',
            style: {{
                "shape": "diamond",
                "background-color": "#bbf7d0",
                "width": 85,
                "height": 65
            }}
        }},

        {{
            selector: 'node[type="Materials"]',
            style: {{
                "shape": "round-rectangle",
                "background-color": "#ecfccb"
            }}
        }},

        {{
            selector: 'node[type="Time"]',
            style: {{
                "shape": "hexagon",
                "background-color": "#f3e8ff"
            }}
        }},

        {{
            selector: 'node[type="Setup"]',
            style: {{
                "shape": "ellipse",
                "background-color": "#fee2e2"
            }}
        }},

        {{
            selector: 'node[type="Processing"]',
            style: {{
                "shape": "ellipse",
                "background-color": "#fef3c7"
            }}
        }},

        {{
            selector: 'node[type ^= "Literal"]',
            style: {{
                "shape": "round-rectangle",
                "background-color": "#f3f4f6",
                "font-size": 9
            }}
        }},

        {{
            selector: "edge",
            style: {{
                "curve-style": "bezier",
                "target-arrow-shape": "triangle",
                "line-color": "#94a3b8",
                "target-arrow-color": "#94a3b8",
                "width": 1.2,
                "label": "data(label)",
                "font-size": 8,
                "text-background-color": "#ffffff",
                "text-background-opacity": 0.9,
                "text-background-padding": 2
            }}
        }},

        {{
            selector: 'edge[label="next"]',
            style: {{
                "width": 2.5,
                "line-color": "#475569",
                "target-arrow-color": "#475569"
            }}
        }},

        {{
            selector: ":selected",
            style: {{
                "border-width": 3,
                "border-color": "#2563eb",
                "line-color": "#2563eb",
                "target-arrow-color": "#2563eb"
            }}
        }}

    ],

    layout: {{
        name: "breadthfirst",
        directed: true,
        padding: 30,
        spacingFactor: 1.25
    }},

    wheelSensitivity: 0.2
}});


function layoutOptions() {{

    const name = layoutSelect.value;

    if (name === "breadthfirst") {{
        return {{
            name,
            directed: true,
            padding: 30,
            spacingFactor: 1.25,
            animate: false
        }};
    }}

    if (name === "cose") {{
        return {{
            name,
            padding: 30,
            animate: false,
            nodeRepulsion: 500000,
            idealEdgeLength: 90
        }};
    }}

    return {{
        name,
        padding: 30,
        animate: false
    }};
}}


function updateStatus() {{

    const dataset = datasetSelect.value;

    status.textContent =
        `${{TRIPLE_COUNTS[dataset]}} triples · ` +
        `${{cy.nodes().length}} nodes · ` +
        `${{cy.edges().length}} edges`;
}}


function reloadDataset() {{

    const dataset = datasetSelect.value;

    cy.elements().remove();
    cy.add(DATASETS[dataset]);

    cy.layout(layoutOptions()).run();
    cy.fit(undefined, 25);

    updateStatus();

    detailsText.innerHTML =
        "点击节点或边查看 RDF 信息。";
}}


function escapeHtml(value) {{

    return String(value ?? "")
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;");
}}


function showDetails(rows) {{

    detailsText.innerHTML = rows.map(row => `
        <div class="k">${{escapeHtml(row[0])}}</div>
        <div class="v">${{escapeHtml(row[1])}}</div>
    `).join("");
}}


cy.on("tap", "node", event => {{

    const d = event.target.data();

    showDetails([
        ["Label", d.label],
        ["Node type", d.type],
        ["Full URI / value", d.full],
        ["RDF types", (d.rdfTypes || []).join(", ")],
        ["Datatype", d.datatype],
        ["Language", d.language]
    ]);
}});


cy.on("tap", "edge", event => {{

    const e = event.target;

    showDetails([
        ["Predicate", e.data("label")],
        ["Predicate URI", e.data("predicate")],
        ["Source", e.source().data("full")],
        ["Target", e.target().data("full")]
    ]);
}});


datasetSelect.addEventListener(
    "change",
    reloadDataset
);


layoutSelect.addEventListener(
    "change",
    () => {{
        cy.layout(layoutOptions()).run();

        setTimeout(
            () => cy.fit(undefined, 25),
            30
        );
    }}
);


edgeLabelSelect.addEventListener(
    "change",
    () => {{

        const show =
            edgeLabelSelect.value === "show";

        cy.style()
            .selector("edge")
            .style(
                "label",
                show ? "data(label)" : ""
            )
            .update();
    }}
);


document.getElementById("fit")
    .addEventListener(
        "click",
        () => cy.fit(undefined, 25)
    );


document.getElementById("reset")
    .addEventListener(
        "click",
        () => {{
            cy.layout(layoutOptions()).run();

            setTimeout(
                () => cy.fit(undefined, 25),
                30
            );
        }}
    );


updateStatus();

setTimeout(
    () => cy.fit(undefined, 25),
    100
);

</script>

</body>
</html>
"""


def main():
    parser = argparse.ArgumentParser(
        description="Convert RDF/Turtle files into an interactive Cytoscape.js HTML viewer."
    )

    parser.add_argument(
        "ttl",
        nargs="+",
        help="One or more .ttl files"
    )

    parser.add_argument(
        "--out",
        default="cytoscape_graph.html",
        help="Output HTML path"
    )

    args = parser.parse_args()

    datasets = {}
    combined = Graph()

    for filename in args.ttl:

        path = Path(filename)

        g = Graph()
        g.parse(path, format="turtle")

        name = path.stem

        datasets[name] = graph_to_elements(g)

        for triple in g:
            combined.add(triple)

    if len(datasets) > 1:
        datasets["ALL"] = graph_to_elements(combined)

    triple_counts = {}

    for filename in args.ttl:
        path = Path(filename)

        g = Graph()
        g.parse(path, format="turtle")

        triple_counts[path.stem] = len(g)

    if len(datasets) > 1:
        triple_counts["ALL"] = len(combined)

    output = Path(args.out)

    output.write_text(
        generate_html(
            datasets,
            triple_counts
        ),
        encoding="utf-8"
    )

    print(f"Generated: {output.resolve()}")


if __name__ == "__main__":
    main()