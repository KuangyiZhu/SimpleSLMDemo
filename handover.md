# Fuseki / SPARQL 会话交接

更新日期：2026-09-24（Asia/Tokyo）
项目：`/Users/kuangyizhu/codexdir/aidemo`

## 下次如何继续

向新会话发送：

> 读取 handover.md，先检查 Fuseki 的实际运行状态，再继续 knowledge 数据集的 SPARQL 查询与图遍历讨论。启动服务时使用 .agent/skills/start-fuseki/SKILL.md。

当前没有尚待执行的数据库修改。最后讨论到：SPARQL 的路径查询如何处理环、为什么不会仅因有环就无限循环，以及慢查询与死循环的区别。用户正在理解图查询的逻辑与执行机制，可以结合制造数据继续说明或验证具体查询。

本文件是交接摘要，不包含昨天完整会话。昨天关于“验证 Fuseki 的 SPARQL”的具体要求在今天会话中不可见，不要假定已经完成所有历史验证。

## 今天完成的操作及最终状态

1. 找到 Apache Jena Fuseki 6.2.0，使用本机 Java 21 启动。
2. 初次启动时，`run/configuration` 为空，日志显示 `No databases`。
3. 将 `skill_data` 下全部三个 TTL 文件导入新建的 TDB2 数据集 `manufacturing`，验证得到 469 条去重后的三元组。
4. 随后发现昨天的数据库仍在 `databases/knowledge`。问题是本次运行目录缺少指向它的数据集配置，并不能据此断言昨天数据丢失。昨天确切启动命令未查明。
5. 按用户要求，为原数据库保存 `knowledge.ttl` 配置，重启 Fuseki，验证原数据可查询。
6. 通过管理接口删除今天重复创建的 `manufacturing` 数据集。检查确认其配置和 `run/databases/manufacturing` 数据库目录均已移除。
7. 最终管理接口仅列出在线的 `/knowledge`，默认图有 **469 条三元组、3 个产品、每个产品 6 道工序，共 18 道工序**。

上述运行状态是今天最后验证的结果；新会话必须重新检查服务是否仍在运行。不要依赖旧进程 ID，也不要无故重复导入 TTL。

## 路径与启动方式

| 用途 | 路径或地址 |
|---|---|
| Fuseki 安装目录 | `/Users/kuangyizhu/servers/fuseki/apache-jena-fuseki-6.2.0` |
| Java 21 JAVA_HOME | `/usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home` |
| FUSEKI_BASE | `/Users/kuangyizhu/servers/fuseki/run` |
| 原数据库（应保留） | `/Users/kuangyizhu/servers/fuseki/databases/knowledge` |
| 持久化数据集配置 | `/Users/kuangyizhu/servers/fuseki/run/configuration/knowledge.ttl` |
| 管理页面 | `http://localhost:3030/` |
| 管理接口 | `http://localhost:3030/$/datasets` |
| 查询接口 | `http://localhost:3030/knowledge/query` |
| 启动技能 | `.agent/skills/start-fuseki/SKILL.md` |

实际数据集名称是小写 `knowledge`。不要误用 `run/databases/knowledge`，原数据库在 `fuseki/databases/knowledge`。

```bash
cd /Users/kuangyizhu/servers/fuseki
export JAVA_HOME=/usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export FUSEKI_BASE=/Users/kuangyizhu/servers/fuseki/run
./apache-jena-fuseki-6.2.0/fuseki-server
```

启动加载关系：`FUSEKI_BASE` → `configuration/knowledge.ttl` → `tdb2:location` 指定的原数据库。配置内 `fuseki:name` 是 `knowledge`，`tdb2:location` 是上述原数据库绝对路径。TDB2 已持久化，无需每次导入 TTL；修改源 TTL 不会自动更新数据库。

工具执行注意：普通后台 shell 启动曾未保持运行，后改用持续终端会话（`tty: true`）成功。访问 localhost 在沙箱内曾失败，提升权限后可正常连接；不能仅凭沙箱内 curl 失败断定服务停止。外部运行目录的写入也需要按执行工具要求申请权限。

技能按用户明确要求保存在 `.agent`（单数）下。不要假定它会被自动发现，可通过明确路径让后续会话读取。技能已人工检查，但 bundled `quick_validate.py` 因系统 Python 和项目虚拟环境均缺少 `PyYAML` 未能运行。

## 数据结构

源文件：

- `skill_data/KETTLE-001_process.ttl`
- `skill_data/RICECOOKER-001_process.ttl`
- `skill_data/TOASTER-001_process.ttl`

共同前缀：

```sparql
PREFIX mfg: <http://example.org/manufacturing/ontology#>
PREFIX res: <http://example.org/manufacturing/resource/>
```

关系链：

```text
Product --hasProcess--> Process
Process --hasStep--> ProcessStep
ProcessStep --hasMaterials--> Materials
Materials --hasMaterialUsage--> MaterialUsage
MaterialUsage --material--> Material
MaterialUsage --quantityPerPiece--> 单件用量
MaterialUsage --quantityUnit--> 单件用量单位
```

不同产品使用相同材料 URI 时，指向同一个材料节点；具体用量存放在各自的 MaterialUsage 节点上。

## 已实际验证：STEEL-001 反查产品

结果：

| 产品 | 单件钢材用量 |
|---|---:|
| KETTLE-001 | 600 g |
| RICECOOKER-001 | 700 g |
| TOASTER-001 | 800 g |

已执行查询：

```sparql
PREFIX mfg: <http://example.org/manufacturing/ontology#>
PREFIX res: <http://example.org/manufacturing/resource/>

SELECT DISTINCT ?product ?quantity ?unit
WHERE {
  ?product a mfg:Product ;
    mfg:hasProcess/mfg:hasStep/mfg:hasMaterials/mfg:hasMaterialUsage ?usage .
  ?usage mfg:material res:STEEL-001 ;
    mfg:quantityPerPiece ?quantity ;
    mfg:quantityUnit ?unit .
}
ORDER BY ?product
```

也讨论过等价的反向路径表达（下面这个版本只返回产品，今天未单独执行）：

```sparql
PREFIX mfg: <http://example.org/manufacturing/ontology#>
PREFIX res: <http://example.org/manufacturing/resource/>

SELECT DISTINCT ?product
WHERE {
  res:STEEL-001
    ^mfg:material/^mfg:hasMaterialUsage/^mfg:hasMaterials/
    ^mfg:hasStep/^mfg:hasProcess ?product .
  ?product a mfg:Product .
}
```

`/` 表示连续路径，`^` 表示反向匹配关系，不要求另外存储反向边。仅查询 STEEL-001 自身属性并不会自动返回所有关联产品。

## 已实际验证：RICECOOKER 与 KETTLE 的共用原料

实际执行了分别按材料和单位聚合单件用量、再连接两侧结果的查询，得到：

| 材料 | RICECOOKER 单件用量 | KETTLE 单件用量 | 单位 |
|---|---:|---:|---|
| CABLE-001 | 1 | 1 | unit/pc |
| CARTON-001 | 1 | 1 | unit/pc |
| PLASTIC-001 | 350 | 250 | g/pc |
| SCREW-001 | 6 | 4 | unit/pc |
| STEEL-001 | 700 | 600 | g/pc |
| THERMO-001 | 1 | 1 | unit/pc |

只返回原料交集的简化查询：

```sparql
PREFIX mfg: <http://example.org/manufacturing/ontology#>
PREFIX res: <http://example.org/manufacturing/resource/>

SELECT DISTINCT ?material
WHERE {
  res:RICECOOKER-001
    mfg:hasProcess/mfg:hasStep/mfg:hasMaterials/
    mfg:hasMaterialUsage/mfg:material ?material .
  res:KETTLE-001
    mfg:hasProcess/mfg:hasStep/mfg:hasMaterials/
    mfg:hasMaterialUsage/mfg:material ?material .
}
ORDER BY ?material
```

共享 `?material` 变量表示两侧必须匹配同一个材料，逻辑上是集合交集，查询处理上是连接（Join）。`DISTINCT` 对输出去重。

共用材料只表示潜在资源竞争，不能单凭交集认定短缺。实际判断需生产数量、需求时间、可用库存、到货量等信息。例如两类产品各生产 10 台需要 13,000 g 钢材，但今天未查询或验证库存数据。

## 今天讨论的执行原理

- 用户提出“遍历材料，打产品 tag，缓存节点 tag，筛选同时带两个 tag 的材料”。这是可行的理解模型，但不是已确认的 Fuseki 实现。
- SPARQL 是声明式语言，描述匹配条件；书写顺序不等于实际遍历顺序。
- Fuseki 提供服务，底层 Jena ARQ 与存储引擎处理优化、索引和执行。
- 连接可能使用哈希连接或索引连接等方式；今天没有检查实际执行计划，不能声称当前查询一定采用其中某种算法。
- 查询中间状态不是永久写入材料节点的标签。

## 最后讨论：图中有环会不会死循环

对于有限本地 RDF 图和正常实现的标准 SPARQL，环本身不会导致属性路径查询无限循环。

例如假设存在 `A --next--> B --next--> C --next--> A`，查询 `res:A mfg:next+ ?step` 的可达节点包括 B、C、A。`+` 表示一步或多步；`*` 表示零步或多步。任意长度路径求值会处理已访问节点/遍历状态，避免无限展开环。这与最终结果 `DISTINCT` 去重是不同层面的操作。

该环示例仅用于说明，没有向 knowledge 插入示例数据。

参考：[W3C SPARQL 1.1 属性路径求值](https://www.w3.org/TR/sparql11-query/#defn_evalPP)。

需要区别：

- 图中存在环：不会仅因环无限展开。
- 无约束的大范围可达性查询或多个连接产生大量组合：可能很慢、内存耗尽或超时。
- 自定义扩展函数、远程 SERVICE 或实现缺陷：可能阻塞，不能作绝对终止保证。
- `LIMIT` 限制返回数量，不保证执行很快；查询超时可控制运行时间，但今天未修改超时配置。
- 标准 SPARQL 适合路径匹配、可达性、连接与属性过滤，不等于能直接表达所有任意图算法；逐步维护累计状态并以此控制后续遍历等需求可能需要额外程序或扩展。

## 会话恢复的经验

在聊天框输入 `resume` 或 `resume --last` 只是普通消息，不会切换历史会话。在终端进入本项目后运行 `codex resume`，从列表选择目标会话；`codex resume --last` 恢复最近一次，可能已经是今天这次而不是昨天。

恢复对话不会自动启动 Fuseki。新会话也可以直接读取本交接文件继续，避免依赖是否选中了正确的历史会话。
