# Discrete Manufacturing Sample Data

本数据集用于模拟一个离散制造场景，产品为：

- `KETTLE-001`：电热水壶
- `TOASTER-001`：烤面包机
- `RICECOOKER-001`：电饭煲

整体数据分为两类：

```text
Master Data
├── Material
├── BOM
├── Work Center
├── Capacity
├── Routing
└── Production Version

Transaction / Runtime Data
├── Inventory
├── Production Order
├── Order Operation
└── Machine Status
```

---

# 1. Material Master

产品、半成品、原料统一作为 Material。

| material_id | material_code | material_type | description | base_unit |
|---:|---|---|---|---|
| 1 | KETTLE-001 | FERT | 电热水壶 | EA |
| 2 | TOASTER-001 | FERT | 烤面包机 | EA |
| 3 | RICECOOKER-001 | FERT | 电饭煲 | EA |
| 101 | STEEL-001 | ROH | 不锈钢板 | KG |
| 102 | PLASTIC-001 | ROH | 塑料粒子 | KG |
| 103 | CABLE-001 | ROH | 电源线 | EA |
| 104 | THERMO-001 | ROH | 温控器 | EA |
| 105 | SCREW-001 | ROH | 螺丝 | EA |
| 106 | HEATER-K-001 | ROH | 水壶加热盘 | EA |
| 107 | HEATING-WIRE-001 | ROH | 烤面包机电热丝 | EA |
| 108 | INNER-POT-001 | ROH | 电饭煲内胆 | EA |
| 109 | PCB-001 | ROH | 控制板 | EA |
| 110 | SPRING-001 | ROH | 弹簧机构 | EA |
| 111 | CARTON-001 | ROH | 包装纸箱 | EA |

```text
FERT = Finished Product
ROH  = Raw Material
HALB = Semi-finished Product
```

---

# 2. BOM Header

每个产品一个 BOM。

| bom_id | bom_code | product_id | product_code | version | valid_from | valid_to |
|---:|---|---:|---|---|---|---|
| 1001 | BOM-KETTLE-01 | 1 | KETTLE-001 | 01 | 2026-01-01 | 9999-12-31 |
| 1002 | BOM-TOASTER-01 | 2 | TOASTER-001 | 01 | 2026-01-01 | 9999-12-31 |
| 1003 | BOM-RICE-01 | 3 | RICECOOKER-001 | 01 | 2026-01-01 | 9999-12-31 |

---

# 3. BOM Item

## 电热水壶 BOM

| bom_id | item_no | component_id | component_code | quantity | unit |
|---:|---:|---:|---|---:|---|
| 1001 | 10 | 101 | STEEL-001 | 0.60 | KG |
| 1001 | 20 | 102 | PLASTIC-001 | 0.25 | KG |
| 1001 | 30 | 103 | CABLE-001 | 1 | EA |
| 1001 | 40 | 104 | THERMO-001 | 1 | EA |
| 1001 | 50 | 105 | SCREW-001 | 4 | EA |
| 1001 | 60 | 106 | HEATER-K-001 | 1 | EA |
| 1001 | 70 | 111 | CARTON-001 | 1 | EA |

## 烤面包机 BOM

| bom_id | item_no | component_id | component_code | quantity | unit |
|---:|---:|---:|---|---:|---|
| 1002 | 10 | 101 | STEEL-001 | 0.80 | KG |
| 1002 | 20 | 102 | PLASTIC-001 | 0.20 | KG |
| 1002 | 30 | 103 | CABLE-001 | 1 | EA |
| 1002 | 40 | 104 | THERMO-001 | 1 | EA |
| 1002 | 50 | 105 | SCREW-001 | 6 | EA |
| 1002 | 60 | 107 | HEATING-WIRE-001 | 2 | EA |
| 1002 | 70 | 110 | SPRING-001 | 2 | EA |
| 1002 | 80 | 111 | CARTON-001 | 1 | EA |

## 电饭煲 BOM

| bom_id | item_no | component_id | component_code | quantity | unit |
|---:|---:|---:|---|---:|---|
| 1003 | 10 | 101 | STEEL-001 | 0.70 | KG |
| 1003 | 20 | 102 | PLASTIC-001 | 0.35 | KG |
| 1003 | 30 | 103 | CABLE-001 | 1 | EA |
| 1003 | 40 | 104 | THERMO-001 | 1 | EA |
| 1003 | 50 | 105 | SCREW-001 | 6 | EA |
| 1003 | 60 | 108 | INNER-POT-001 | 1 | EA |
| 1003 | 70 | 109 | PCB-001 | 1 | EA |
| 1003 | 80 | 111 | CARTON-001 | 1 | EA |

## 原料竞争关系

| 原料 | 水壶 | 烤面包机 | 电饭煲 |
|---|---:|---:|---:|
| STEEL-001 | ✓ | ✓ | ✓ |
| PLASTIC-001 | ✓ | ✓ | ✓ |
| CABLE-001 | ✓ | ✓ | ✓ |
| THERMO-001 | ✓ | ✓ | ✓ |
| HEATER-K-001 | ✓ |  |  |
| HEATING-WIRE-001 |  | ✓ |  |
| INNER-POT-001 |  |  | ✓ |
| PCB-001 |  |  | ✓ |
| SPRING-001 |  | ✓ |  |

---

# 4. Work Center

| work_center_id | work_center_code | description | resource_type |
|---:|---|---|---|
| 201 | PRESS-01 | 金属冲压机 | MACHINE |
| 202 | INJECTION-01 | 注塑机 | MACHINE |
| 203 | WELD-01 | 点焊机 | MACHINE |
| 204 | ASSY-KETTLE-01 | 水壶装配线 | LINE |
| 205 | ASSY-TOASTER-01 | 烤面包机装配线 | LINE |
| 206 | ASSY-RICE-01 | 电饭煲装配线 | LINE |
| 207 | PCB-TEST-01 | PCB测试机 | MACHINE |
| 208 | SAFETY-TEST-01 | 安规测试机 | MACHINE |
| 209 | PACK-01 | 包装线 | LINE |

```text
Shared:
PRESS-01
INJECTION-01
SAFETY-TEST-01
PACK-01

Dedicated:
ASSY-KETTLE-01
ASSY-TOASTER-01
ASSY-RICE-01
```

---

# 5. Work Center Capacity

| work_center_id | work_center_code | date | start_time | end_time | available_minutes |
|---:|---|---|---|---|---:|
| 201 | PRESS-01 | 2026-09-21 | 08:00 | 17:00 | 480 |
| 202 | INJECTION-01 | 2026-09-21 | 08:00 | 17:00 | 480 |
| 203 | WELD-01 | 2026-09-21 | 08:00 | 17:00 | 480 |
| 204 | ASSY-KETTLE-01 | 2026-09-21 | 08:00 | 17:00 | 480 |
| 205 | ASSY-TOASTER-01 | 2026-09-21 | 08:00 | 17:00 | 480 |
| 206 | ASSY-RICE-01 | 2026-09-21 | 08:00 | 17:00 | 480 |
| 207 | PCB-TEST-01 | 2026-09-21 | 08:00 | 17:00 | 480 |
| 208 | SAFETY-TEST-01 | 2026-09-21 | 08:00 | 17:00 | 480 |
| 209 | PACK-01 | 2026-09-21 | 08:00 | 17:00 | 480 |

后续可扩展：

```text
break_minutes
capacity_utilization
number_of_parallel_units
overtime_minutes
maintenance_minutes
```

---

# 6. Routing Header

| routing_id | routing_code | product_id | product_code | version |
|---:|---|---:|---|---|
| 2001 | RT-KETTLE-01 | 1 | KETTLE-001 | 01 |
| 2002 | RT-TOASTER-01 | 2 | TOASTER-001 | 01 |
| 2003 | RT-RICE-01 | 3 | RICECOOKER-001 | 01 |

---

# 7. Routing Operation

## 电热水壶 Routing

| routing_id | operation_no | operation_name | work_center_id | work_center | setup_min | process_sec_per_unit |
|---:|---:|---|---:|---|---:|---:|
| 2001 | 10 | 金属冲压 | 201 | PRESS-01 | 20 | 30 |
| 2001 | 20 | 注塑 | 202 | INJECTION-01 | 30 | 45 |
| 2001 | 30 | 点焊 | 203 | WELD-01 | 10 | 20 |
| 2001 | 40 | 总装 | 204 | ASSY-KETTLE-01 | 15 | 90 |
| 2001 | 50 | 安规测试 | 208 | SAFETY-TEST-01 | 5 | 45 |
| 2001 | 60 | 包装 | 209 | PACK-01 | 5 | 30 |

## 烤面包机 Routing

| routing_id | operation_no | operation_name | work_center_id | work_center | setup_min | process_sec_per_unit |
|---:|---:|---|---:|---|---:|---:|
| 2002 | 10 | 金属冲压 | 201 | PRESS-01 | 25 | 40 |
| 2002 | 20 | 注塑 | 202 | INJECTION-01 | 25 | 30 |
| 2002 | 30 | 点焊 | 203 | WELD-01 | 15 | 30 |
| 2002 | 40 | 总装 | 205 | ASSY-TOASTER-01 | 15 | 100 |
| 2002 | 50 | 安规测试 | 208 | SAFETY-TEST-01 | 5 | 50 |
| 2002 | 60 | 包装 | 209 | PACK-01 | 5 | 35 |

## 电饭煲 Routing

| routing_id | operation_no | operation_name | work_center_id | work_center | setup_min | process_sec_per_unit |
|---:|---:|---|---:|---|---:|---:|
| 2003 | 10 | 金属冲压 | 201 | PRESS-01 | 30 | 35 |
| 2003 | 20 | 注塑 | 202 | INJECTION-01 | 30 | 60 |
| 2003 | 30 | PCB测试 | 207 | PCB-TEST-01 | 10 | 40 |
| 2003 | 40 | 总装 | 206 | ASSY-RICE-01 | 20 | 120 |
| 2003 | 50 | 安规测试 | 208 | SAFETY-TEST-01 | 5 | 60 |
| 2003 | 60 | 包装 | 209 | PACK-01 | 5 | 40 |

## 机器竞争关系

| Work Center | 水壶 | 烤面包机 | 电饭煲 |
|---|---:|---:|---:|
| PRESS-01 | ✓ | ✓ | ✓ |
| INJECTION-01 | ✓ | ✓ | ✓ |
| WELD-01 | ✓ | ✓ |  |
| PCB-TEST-01 |  |  | ✓ |
| ASSY-KETTLE-01 | ✓ |  |  |
| ASSY-TOASTER-01 |  | ✓ |  |
| ASSY-RICE-01 |  |  | ✓ |
| SAFETY-TEST-01 | ✓ | ✓ | ✓ |
| PACK-01 | ✓ | ✓ | ✓ |

---

# 8. Production Version

| production_version_id | product_id | product_code | version | bom_id | routing_id | valid_from | valid_to |
|---:|---:|---|---|---:|---:|---|---|
| 3001 | 1 | KETTLE-001 | 01 | 1001 | 2001 | 2026-01-01 | 9999-12-31 |
| 3002 | 2 | TOASTER-001 | 01 | 1002 | 2002 | 2026-01-01 | 9999-12-31 |
| 3003 | 3 | RICECOOKER-001 | 01 | 1003 | 2003 | 2026-01-01 | 9999-12-31 |

```text
KETTLE-001
    │
    ↓
Production Version 01
    ├── BOM 1001
    └── Routing 2001
```

---

# 9. Inventory

| material_id | material_code | plant | storage_location | quantity | unit |
|---:|---|---|---|---:|---|
| 101 | STEEL-001 | PLANT-01 | RAW-01 | 1200 | KG |
| 102 | PLASTIC-001 | PLANT-01 | RAW-01 | 600 | KG |
| 103 | CABLE-001 | PLANT-01 | RAW-01 | 1800 | EA |
| 104 | THERMO-001 | PLANT-01 | RAW-01 | 1600 | EA |
| 105 | SCREW-001 | PLANT-01 | RAW-01 | 10000 | EA |
| 106 | HEATER-K-001 | PLANT-01 | RAW-01 | 700 | EA |
| 107 | HEATING-WIRE-001 | PLANT-01 | RAW-01 | 1200 | EA |
| 108 | INNER-POT-001 | PLANT-01 | RAW-01 | 500 | EA |
| 109 | PCB-001 | PLANT-01 | RAW-01 | 450 | EA |
| 110 | SPRING-001 | PLANT-01 | RAW-01 | 1400 | EA |
| 111 | CARTON-001 | PLANT-01 | PACK-01 | 2000 | EA |

---

# 10. Production Order

| order_id | order_code | product_id | product_code | quantity | release_date | due_date | priority | status |
|---:|---|---:|---|---:|---|---|---:|---|
| 4001 | PO-20260921-001 | 1 | KETTLE-001 | 500 | 2026-09-21 08:00 | 2026-09-21 17:00 | 2 | RELEASED |
| 4002 | PO-20260921-002 | 2 | TOASTER-001 | 300 | 2026-09-21 08:00 | 2026-09-22 12:00 | 3 | RELEASED |
| 4003 | PO-20260921-003 | 3 | RICECOOKER-001 | 250 | 2026-09-21 08:00 | 2026-09-21 18:00 | 1 | RELEASED |
| 4004 | PO-20260921-004 | 1 | KETTLE-001 | 200 | 2026-09-21 12:00 | 2026-09-22 15:00 | 4 | CREATED |

```text
priority 越小越高

1 = Highest
4 = Lowest
```

---

# 11. Production Order Operation

| order_id | operation_no | work_center | quantity | planned_start | planned_end | actual_start | actual_end | status |
|---:|---:|---|---:|---|---|---|---|---|
| 4001 | 10 | PRESS-01 | 500 | NULL | NULL | NULL | NULL | WAITING |
| 4001 | 20 | INJECTION-01 | 500 | NULL | NULL | NULL | NULL | WAITING |
| 4001 | 30 | WELD-01 | 500 | NULL | NULL | NULL | NULL | WAITING |
| 4001 | 40 | ASSY-KETTLE-01 | 500 | NULL | NULL | NULL | NULL | WAITING |
| 4001 | 50 | SAFETY-TEST-01 | 500 | NULL | NULL | NULL | NULL | WAITING |
| 4001 | 60 | PACK-01 | 500 | NULL | NULL | NULL | NULL | WAITING |

一开始：

```text
planned_start
planned_end
```

可以为空。

之后由 CP-SAT Scheduler 算出来并写回。

---

# 12. Machine Status

| work_center_id | work_center_code | timestamp | status | available |
|---:|---|---|---|---|
| 201 | PRESS-01 | 2026-09-21 08:00 | RUNNING | TRUE |
| 202 | INJECTION-01 | 2026-09-21 08:00 | RUNNING | TRUE |
| 203 | WELD-01 | 2026-09-21 08:00 | RUNNING | TRUE |
| 204 | ASSY-KETTLE-01 | 2026-09-21 08:00 | RUNNING | TRUE |
| 205 | ASSY-TOASTER-01 | 2026-09-21 08:00 | RUNNING | TRUE |
| 206 | ASSY-RICE-01 | 2026-09-21 08:00 | RUNNING | TRUE |
| 207 | PCB-TEST-01 | 2026-09-21 08:00 | RUNNING | TRUE |
| 208 | SAFETY-TEST-01 | 2026-09-21 08:00 | RUNNING | TRUE |
| 209 | PACK-01 | 2026-09-21 08:00 | RUNNING | TRUE |

故障事件示例：

| work_center_id | work_center_code | timestamp | status | available |
|---:|---|---|---|---|
| 201 | PRESS-01 | 2026-09-21 11:20 | BREAKDOWN | FALSE |

---

# 13. 整体关系

```text
Material
   │
   ├──────────────┐
   │              │
   ↓              ↓
BOM Header    Routing Header
   │              │
   ↓              ↓
BOM Item      Routing Operation
   │              │
   ↓              ↓
Material       Work Center
                  │
                  ↓
               Capacity


Material
   │
   ↓
Production Version
   │
   ├── BOM
   └── Routing


Production Version
        │
        ↓
Production Order
        │
        ↓
Production Order Operation
        │
        ↓
     Scheduler
```

---

# 14. CP-SAT 第一版最小输入

| 数据集 | 用途 |
|---|---|
| `material` | 产品/原料 |
| `bom_item` | 原料约束 |
| `routing_operation` | 工序顺序 + processing time |
| `work_center_capacity` | 机器能力 |
| `inventory` | 原料库存 |
| `production_order` | 生产需求 + due date |

```text
Orders
+
BOM
+
Routing
+
Inventory
+
Capacity
→
CP-SAT
→
Schedule
```
