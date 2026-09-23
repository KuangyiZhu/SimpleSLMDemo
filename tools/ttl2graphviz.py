from rdflib import Graph
from graphviz import Digraph

g = Graph()
g.parse("KETTLE-001_process.ttl", format="turtle")

dot = Digraph("manufacturing")

for s, p, o in g:
    dot.node(str(s), str(s).split("/")[-1])
    dot.node(str(o), str(o).split("/")[-1])
    dot.edge(
        str(s),
        str(o),
        label=str(p).split("#")[-1]
    )

dot.render("kettle", format="svg", cleanup=True)