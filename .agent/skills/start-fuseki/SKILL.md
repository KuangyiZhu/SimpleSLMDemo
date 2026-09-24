---
name: start-fuseki
description: 启动或重启本机 Apache Jena Fuseki，并恢复既有 knowledge TDB2 数据集。适用于本项目的 Fuseki 启动和数据集恢复请求。
---

# 启动 Fuseki knowledge

## 本机固定配置

- 安装目录：`/Users/kuangyizhu/servers/fuseki/apache-jena-fuseki-6.2.0`
- Java 21：`/usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home`
- `FUSEKI_BASE`：`/Users/kuangyizhu/servers/fuseki/run`
- 数据集配置：`/Users/kuangyizhu/servers/fuseki/run/configuration/knowledge.ttl`
- 既有数据库：`/Users/kuangyizhu/servers/fuseki/databases/knowledge`
- 数据集名称为小写 `knowledge`，查询地址为 `http://localhost:3030/knowledge/query`。

## 操作流程

1. 检查 3030 端口和 `http://localhost:3030/$/datasets`。若 knowledge 已正常运行，直接验证并返回地址；只有用户要求重启时才停止服务。确认监听进程属于此 Fuseki 后使用 SIGTERM，等待端口释放；不要终止其他 Java 服务。
2. 确认既有数据库目录存在且包含 `Data-*` 文件夹。目录缺失时停止并说明情况，不要创建空数据库冒充恢复成功。
3. 检查 `configuration/knowledge.ttl`。它必须声明 `fuseki:name "knowledge"`、类型 `tdb2:DatasetTDB2`，并将 `tdb2:location` 指向上述既有数据库。不要误用 `run/databases/knowledge`。若配置缺失，在启动前使用下方配置补齐；若已有配置不同，先检查原因，避免直接覆盖。
4. 使用以下命令启动。通过工具启动时使用持续终端会话（`tty: true`），等待日志出现 `Start Fuseki`；此环境曾出现普通 shell 后台进程未保持运行的情况。工作区外写入和本机网络访问受沙箱限制时，通过执行工具请求所需权限。

```bash
cd /Users/kuangyizhu/servers/fuseki
export JAVA_HOME=/usr/local/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export FUSEKI_BASE=/Users/kuangyizhu/servers/fuseki/run
./apache-jena-fuseki-6.2.0/fuseki-server
```

5. 查询管理接口确认 `/knowledge` 在线，再运行 `SELECT (COUNT(*) AS ?triples) WHERE { ?s ?p ?o }` 验证可读取数据。2026-09-24 恢复时默认图有 469 条三元组、3 个产品、18 道工序；这是历史基线，不应强制要求未来数据量保持一致。
6. 返回管理地址 `http://localhost:3030/` 和查询地址。启动只打开现有数据库，无需再次导入 `skill_data/*.ttl`，也不要自动创建 manufacturing 数据集或清理其他数据集。

## 配置缺失时的内容

```turtle
@prefix fuseki: <http://jena.apache.org/fuseki#> .
@prefix tdb2: <http://jena.apache.org/2016/tdb#> .
@prefix : <http://example.org/fuseki-config#> .

:service a fuseki:Service ;
    fuseki:name "knowledge" ;
    fuseki:serviceQuery "query", "sparql", "" ;
    fuseki:serviceUpdate "update", "" ;
    fuseki:serviceReadGraphStore "get" ;
    fuseki:serviceReadWriteGraphStore "data", "" ;
    fuseki:serviceUpload "upload" ;
    fuseki:dataset :dataset .

:dataset a tdb2:DatasetTDB2 ;
    tdb2:location "/Users/kuangyizhu/servers/fuseki/databases/knowledge" .
```
