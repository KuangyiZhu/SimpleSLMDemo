-- ============================================================
-- Discrete Manufacturing Sample Database
-- MySQL 8.0+
-- Products:
--   KETTLE-001
--   TOASTER-001
--   RICECOOKER-001
-- ============================================================

CREATE DATABASE IF NOT EXISTS manufacturing_demo
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE manufacturing_demo;

-- ============================================================
-- 1. Material Master
-- ============================================================

DROP TABLE IF EXISTS machine_status;
DROP TABLE IF EXISTS production_order_operation;
DROP TABLE IF EXISTS production_order;
DROP TABLE IF EXISTS inventory;
DROP TABLE IF EXISTS production_version;
DROP TABLE IF EXISTS routing_operation;
DROP TABLE IF EXISTS routing_header;
DROP TABLE IF EXISTS work_center_capacity;
DROP TABLE IF EXISTS work_center;
DROP TABLE IF EXISTS bom_item;
DROP TABLE IF EXISTS bom_header;
DROP TABLE IF EXISTS material;

CREATE TABLE material (
    material_id     BIGINT PRIMARY KEY,
    material_code   VARCHAR(50) NOT NULL UNIQUE,
    material_type   ENUM('FERT', 'HALB', 'ROH') NOT NULL,
    description     VARCHAR(255) NOT NULL,
    base_unit       VARCHAR(10) NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                    ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================================
-- 2. BOM Header
-- ============================================================

CREATE TABLE bom_header (
    bom_id          BIGINT PRIMARY KEY,
    bom_code        VARCHAR(50) NOT NULL UNIQUE,
    product_id      BIGINT NOT NULL,
    version         VARCHAR(20) NOT NULL,
    valid_from      DATE NOT NULL,
    valid_to        DATE NOT NULL,
    CONSTRAINT fk_bom_header_product
        FOREIGN KEY (product_id)
        REFERENCES material(material_id),
    CONSTRAINT chk_bom_validity
        CHECK (valid_to >= valid_from),
    UNIQUE KEY uk_bom_product_version (product_id, version)
) ENGINE=InnoDB;

-- ============================================================
-- 3. BOM Item
-- ============================================================

CREATE TABLE bom_item (
    bom_id          BIGINT NOT NULL,
    item_no         INT NOT NULL,
    component_id    BIGINT NOT NULL,
    quantity        DECIMAL(18,6) NOT NULL,
    unit            VARCHAR(10) NOT NULL,
    scrap_rate      DECIMAL(7,4) NOT NULL DEFAULT 0,
    PRIMARY KEY (bom_id, item_no),
    CONSTRAINT fk_bom_item_header
        FOREIGN KEY (bom_id)
        REFERENCES bom_header(bom_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_bom_item_component
        FOREIGN KEY (component_id)
        REFERENCES material(material_id),
    CONSTRAINT chk_bom_quantity
        CHECK (quantity > 0),
    CONSTRAINT chk_bom_scrap_rate
        CHECK (scrap_rate >= 0 AND scrap_rate < 1),
    KEY idx_bom_item_component (component_id)
) ENGINE=InnoDB;

-- ============================================================
-- 4. Work Center
-- ============================================================

CREATE TABLE work_center (
    work_center_id      BIGINT PRIMARY KEY,
    work_center_code    VARCHAR(50) NOT NULL UNIQUE,
    description         VARCHAR(255) NOT NULL,
    resource_type       ENUM('MACHINE', 'LINE', 'LABOR', 'TOOL') NOT NULL,
    active              BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

-- ============================================================
-- 5. Work Center Capacity
-- ============================================================

CREATE TABLE work_center_capacity (
    work_center_id          BIGINT NOT NULL,
    capacity_date           DATE NOT NULL,
    start_time              TIME NOT NULL,
    end_time                TIME NOT NULL,
    available_minutes       INT NOT NULL,
    break_minutes           INT NOT NULL DEFAULT 0,
    overtime_minutes        INT NOT NULL DEFAULT 0,
    parallel_units          INT NOT NULL DEFAULT 1,
    capacity_utilization    DECIMAL(7,4) NOT NULL DEFAULT 1.0000,
    PRIMARY KEY (work_center_id, capacity_date),
    CONSTRAINT fk_capacity_work_center
        FOREIGN KEY (work_center_id)
        REFERENCES work_center(work_center_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_available_minutes
        CHECK (available_minutes >= 0),
    CONSTRAINT chk_break_minutes
        CHECK (break_minutes >= 0),
    CONSTRAINT chk_overtime_minutes
        CHECK (overtime_minutes >= 0),
    CONSTRAINT chk_parallel_units
        CHECK (parallel_units >= 1),
    CONSTRAINT chk_capacity_utilization
        CHECK (capacity_utilization > 0 AND capacity_utilization <= 1)
) ENGINE=InnoDB;

-- ============================================================
-- 6. Routing Header
-- ============================================================

CREATE TABLE routing_header (
    routing_id      BIGINT PRIMARY KEY,
    routing_code    VARCHAR(50) NOT NULL UNIQUE,
    product_id      BIGINT NOT NULL,
    version         VARCHAR(20) NOT NULL,
    valid_from      DATE NOT NULL DEFAULT '2026-01-01',
    valid_to        DATE NOT NULL DEFAULT '9999-12-31',
    CONSTRAINT fk_routing_product
        FOREIGN KEY (product_id)
        REFERENCES material(material_id),
    CONSTRAINT chk_routing_validity
        CHECK (valid_to >= valid_from),
    UNIQUE KEY uk_routing_product_version (product_id, version)
) ENGINE=InnoDB;

-- ============================================================
-- 7. Routing Operation
-- ============================================================

CREATE TABLE routing_operation (
    routing_id             BIGINT NOT NULL,
    operation_no           INT NOT NULL,
    operation_name         VARCHAR(100) NOT NULL,
    work_center_id         BIGINT NOT NULL,
    setup_min              INT NOT NULL DEFAULT 0,
    process_sec_per_unit   DECIMAL(18,4) NOT NULL,
    wait_min               INT NOT NULL DEFAULT 0,
    move_min               INT NOT NULL DEFAULT 0,
    PRIMARY KEY (routing_id, operation_no),
    CONSTRAINT fk_routing_operation_header
        FOREIGN KEY (routing_id)
        REFERENCES routing_header(routing_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_routing_operation_work_center
        FOREIGN KEY (work_center_id)
        REFERENCES work_center(work_center_id),
    CONSTRAINT chk_setup_min
        CHECK (setup_min >= 0),
    CONSTRAINT chk_process_sec
        CHECK (process_sec_per_unit > 0),
    CONSTRAINT chk_wait_min
        CHECK (wait_min >= 0),
    CONSTRAINT chk_move_min
        CHECK (move_min >= 0),
    KEY idx_routing_operation_work_center (work_center_id)
) ENGINE=InnoDB;

-- ============================================================
-- 8. Production Version
-- ============================================================

CREATE TABLE production_version (
    production_version_id  BIGINT PRIMARY KEY,
    product_id              BIGINT NOT NULL,
    version                 VARCHAR(20) NOT NULL,
    bom_id                  BIGINT NOT NULL,
    routing_id              BIGINT NOT NULL,
    valid_from              DATE NOT NULL,
    valid_to                DATE NOT NULL,
    min_lot_size            DECIMAL(18,3) NULL,
    max_lot_size            DECIMAL(18,3) NULL,
    CONSTRAINT fk_prod_ver_product
        FOREIGN KEY (product_id)
        REFERENCES material(material_id),
    CONSTRAINT fk_prod_ver_bom
        FOREIGN KEY (bom_id)
        REFERENCES bom_header(bom_id),
    CONSTRAINT fk_prod_ver_routing
        FOREIGN KEY (routing_id)
        REFERENCES routing_header(routing_id),
    CONSTRAINT chk_prod_ver_validity
        CHECK (valid_to >= valid_from),
    CONSTRAINT chk_prod_ver_lot
        CHECK (
            min_lot_size IS NULL
            OR max_lot_size IS NULL
            OR max_lot_size >= min_lot_size
        ),
    UNIQUE KEY uk_prod_ver_product_version (product_id, version)
) ENGINE=InnoDB;

-- ============================================================
-- 9. Inventory
-- ============================================================

CREATE TABLE inventory (
    inventory_id        BIGINT AUTO_INCREMENT PRIMARY KEY,
    material_id         BIGINT NOT NULL,
    plant               VARCHAR(50) NOT NULL,
    storage_location    VARCHAR(50) NOT NULL,
    quantity            DECIMAL(18,6) NOT NULL,
    unit                VARCHAR(10) NOT NULL,
    reserved_quantity   DECIMAL(18,6) NOT NULL DEFAULT 0,
    updated_at          TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
                        ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_inventory_material
        FOREIGN KEY (material_id)
        REFERENCES material(material_id),
    CONSTRAINT chk_inventory_quantity
        CHECK (quantity >= 0),
    CONSTRAINT chk_reserved_quantity
        CHECK (reserved_quantity >= 0),
    UNIQUE KEY uk_inventory_location
        (material_id, plant, storage_location)
) ENGINE=InnoDB;

-- ============================================================
-- 10. Production Order
-- ============================================================

CREATE TABLE production_order (
    order_id                BIGINT PRIMARY KEY,
    order_code              VARCHAR(50) NOT NULL UNIQUE,
    product_id              BIGINT NOT NULL,
    production_version_id   BIGINT NOT NULL,
    quantity                DECIMAL(18,3) NOT NULL,
    release_date            DATETIME NOT NULL,
    due_date                DATETIME NOT NULL,
    priority                INT NOT NULL,
    status                  ENUM(
                                'CREATED',
                                'RELEASED',
                                'IN_PROCESS',
                                'COMPLETED',
                                'CANCELLED'
                            ) NOT NULL,
    created_at              TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_production_order_product
        FOREIGN KEY (product_id)
        REFERENCES material(material_id),
    CONSTRAINT fk_production_order_version
        FOREIGN KEY (production_version_id)
        REFERENCES production_version(production_version_id),
    CONSTRAINT chk_order_quantity
        CHECK (quantity > 0),
    CONSTRAINT chk_order_dates
        CHECK (due_date >= release_date),
    CONSTRAINT chk_order_priority
        CHECK (priority >= 1)
) ENGINE=InnoDB;

-- ============================================================
-- 11. Production Order Operation
-- ============================================================

CREATE TABLE production_order_operation (
    order_id                BIGINT NOT NULL,
    operation_no            INT NOT NULL,
    operation_name          VARCHAR(100) NOT NULL,
    work_center_id          BIGINT NOT NULL,
    quantity                DECIMAL(18,3) NOT NULL,
    setup_min               INT NOT NULL DEFAULT 0,
    process_sec_per_unit    DECIMAL(18,4) NOT NULL,
    planned_start           DATETIME NULL,
    planned_end             DATETIME NULL,
    actual_start            DATETIME NULL,
    actual_end              DATETIME NULL,
    status                  ENUM(
                                'WAITING',
                                'READY',
                                'RUNNING',
                                'COMPLETED',
                                'BLOCKED'
                            ) NOT NULL DEFAULT 'WAITING',
    PRIMARY KEY (order_id, operation_no),
    CONSTRAINT fk_order_operation_order
        FOREIGN KEY (order_id)
        REFERENCES production_order(order_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_order_operation_work_center
        FOREIGN KEY (work_center_id)
        REFERENCES work_center(work_center_id),
    CONSTRAINT chk_order_operation_quantity
        CHECK (quantity > 0),
    CONSTRAINT chk_order_operation_setup
        CHECK (setup_min >= 0),
    CONSTRAINT chk_order_operation_process
        CHECK (process_sec_per_unit > 0),
    KEY idx_order_operation_work_center (work_center_id),
    KEY idx_order_operation_status (status)
) ENGINE=InnoDB;

-- ============================================================
-- 12. Machine Status
-- ============================================================

CREATE TABLE machine_status (
    machine_status_id   BIGINT AUTO_INCREMENT PRIMARY KEY,
    work_center_id      BIGINT NOT NULL,
    status_timestamp    DATETIME NOT NULL,
    status              ENUM(
                            'RUNNING',
                            'IDLE',
                            'SETUP',
                            'BREAKDOWN',
                            'MAINTENANCE',
                            'OFFLINE'
                        ) NOT NULL,
    available           BOOLEAN NOT NULL,
    note                VARCHAR(255) NULL,
    CONSTRAINT fk_machine_status_work_center
        FOREIGN KEY (work_center_id)
        REFERENCES work_center(work_center_id),
    KEY idx_machine_status_wc_time
        (work_center_id, status_timestamp)
) ENGINE=InnoDB;

-- ============================================================
-- SAMPLE DATA
-- ============================================================

-- ------------------------------------------------------------
-- Material
-- ------------------------------------------------------------

INSERT INTO material
(material_id, material_code, material_type, description, base_unit)
VALUES
(1,   'KETTLE-001',       'FERT', '电热水壶',         'EA'),
(2,   'TOASTER-001',      'FERT', '烤面包机',         'EA'),
(3,   'RICECOOKER-001',   'FERT', '电饭煲',           'EA'),
(101, 'STEEL-001',        'ROH',  '不锈钢板',         'KG'),
(102, 'PLASTIC-001',      'ROH',  '塑料粒子',         'KG'),
(103, 'CABLE-001',        'ROH',  '电源线',           'EA'),
(104, 'THERMO-001',       'ROH',  '温控器',           'EA'),
(105, 'SCREW-001',        'ROH',  '螺丝',             'EA'),
(106, 'HEATER-K-001',     'ROH',  '水壶加热盘',       'EA'),
(107, 'HEATING-WIRE-001', 'ROH',  '烤面包机电热丝',   'EA'),
(108, 'INNER-POT-001',    'ROH',  '电饭煲内胆',       'EA'),
(109, 'PCB-001',          'ROH',  '控制板',           'EA'),
(110, 'SPRING-001',       'ROH',  '弹簧机构',         'EA'),
(111, 'CARTON-001',       'ROH',  '包装纸箱',         'EA');

-- ------------------------------------------------------------
-- BOM Header
-- ------------------------------------------------------------

INSERT INTO bom_header
(bom_id, bom_code, product_id, version, valid_from, valid_to)
VALUES
(1001, 'BOM-KETTLE-01',  1, '01', '2026-01-01', '9999-12-31'),
(1002, 'BOM-TOASTER-01', 2, '01', '2026-01-01', '9999-12-31'),
(1003, 'BOM-RICE-01',    3, '01', '2026-01-01', '9999-12-31');

-- ------------------------------------------------------------
-- BOM Item
-- ------------------------------------------------------------

INSERT INTO bom_item
(bom_id, item_no, component_id, quantity, unit)
VALUES
-- KETTLE
(1001, 10, 101, 0.60, 'KG'),
(1001, 20, 102, 0.25, 'KG'),
(1001, 30, 103, 1.00, 'EA'),
(1001, 40, 104, 1.00, 'EA'),
(1001, 50, 105, 4.00, 'EA'),
(1001, 60, 106, 1.00, 'EA'),
(1001, 70, 111, 1.00, 'EA'),

-- TOASTER
(1002, 10, 101, 0.80, 'KG'),
(1002, 20, 102, 0.20, 'KG'),
(1002, 30, 103, 1.00, 'EA'),
(1002, 40, 104, 1.00, 'EA'),
(1002, 50, 105, 6.00, 'EA'),
(1002, 60, 107, 2.00, 'EA'),
(1002, 70, 110, 2.00, 'EA'),
(1002, 80, 111, 1.00, 'EA'),

-- RICE COOKER
(1003, 10, 101, 0.70, 'KG'),
(1003, 20, 102, 0.35, 'KG'),
(1003, 30, 103, 1.00, 'EA'),
(1003, 40, 104, 1.00, 'EA'),
(1003, 50, 105, 6.00, 'EA'),
(1003, 60, 108, 1.00, 'EA'),
(1003, 70, 109, 1.00, 'EA'),
(1003, 80, 111, 1.00, 'EA');

-- ------------------------------------------------------------
-- Work Center
-- ------------------------------------------------------------

INSERT INTO work_center
(work_center_id, work_center_code, description, resource_type)
VALUES
(201, 'PRESS-01',         '金属冲压机',       'MACHINE'),
(202, 'INJECTION-01',     '注塑机',           'MACHINE'),
(203, 'WELD-01',          '点焊机',           'MACHINE'),
(204, 'ASSY-KETTLE-01',   '水壶装配线',       'LINE'),
(205, 'ASSY-TOASTER-01',  '烤面包机装配线',   'LINE'),
(206, 'ASSY-RICE-01',     '电饭煲装配线',     'LINE'),
(207, 'PCB-TEST-01',      'PCB测试机',        'MACHINE'),
(208, 'SAFETY-TEST-01',   '安规测试机',       'MACHINE'),
(209, 'PACK-01',          '包装线',           'LINE');

-- ------------------------------------------------------------
-- Work Center Capacity
-- ------------------------------------------------------------

INSERT INTO work_center_capacity
(
    work_center_id,
    capacity_date,
    start_time,
    end_time,
    available_minutes,
    break_minutes,
    overtime_minutes,
    parallel_units,
    capacity_utilization
)
VALUES
(201, '2026-09-21', '08:00:00', '17:00:00', 480, 60, 0, 1, 1.0000),
(202, '2026-09-21', '08:00:00', '17:00:00', 480, 60, 0, 1, 1.0000),
(203, '2026-09-21', '08:00:00', '17:00:00', 480, 60, 0, 1, 1.0000),
(204, '2026-09-21', '08:00:00', '17:00:00', 480, 60, 0, 1, 1.0000),
(205, '2026-09-21', '08:00:00', '17:00:00', 480, 60, 0, 1, 1.0000),
(206, '2026-09-21', '08:00:00', '17:00:00', 480, 60, 0, 1, 1.0000),
(207, '2026-09-21', '08:00:00', '17:00:00', 480, 60, 0, 1, 1.0000),
(208, '2026-09-21', '08:00:00', '17:00:00', 480, 60, 0, 1, 1.0000),
(209, '2026-09-21', '08:00:00', '17:00:00', 480, 60, 0, 1, 1.0000);

-- ------------------------------------------------------------
-- Routing Header
-- ------------------------------------------------------------

INSERT INTO routing_header
(routing_id, routing_code, product_id, version, valid_from, valid_to)
VALUES
(2001, 'RT-KETTLE-01',  1, '01', '2026-01-01', '9999-12-31'),
(2002, 'RT-TOASTER-01', 2, '01', '2026-01-01', '9999-12-31'),
(2003, 'RT-RICE-01',    3, '01', '2026-01-01', '9999-12-31');

-- ------------------------------------------------------------
-- Routing Operation
-- ------------------------------------------------------------

INSERT INTO routing_operation
(
    routing_id,
    operation_no,
    operation_name,
    work_center_id,
    setup_min,
    process_sec_per_unit,
    wait_min,
    move_min
)
VALUES
-- KETTLE
(2001, 10, '金属冲压', 201, 20,  30, 0, 0),
(2001, 20, '注塑',     202, 30,  45, 0, 0),
(2001, 30, '点焊',     203, 10,  20, 0, 0),
(2001, 40, '总装',     204, 15,  90, 0, 0),
(2001, 50, '安规测试', 208,  5,  45, 0, 0),
(2001, 60, '包装',     209,  5,  30, 0, 0),

-- TOASTER
(2002, 10, '金属冲压', 201, 25,  40, 0, 0),
(2002, 20, '注塑',     202, 25,  30, 0, 0),
(2002, 30, '点焊',     203, 15,  30, 0, 0),
(2002, 40, '总装',     205, 15, 100, 0, 0),
(2002, 50, '安规测试', 208,  5,  50, 0, 0),
(2002, 60, '包装',     209,  5,  35, 0, 0),

-- RICE COOKER
(2003, 10, '金属冲压', 201, 30,  35, 0, 0),
(2003, 20, '注塑',     202, 30,  60, 0, 0),
(2003, 30, 'PCB测试',  207, 10,  40, 0, 0),
(2003, 40, '总装',     206, 20, 120, 0, 0),
(2003, 50, '安规测试', 208,  5,  60, 0, 0),
(2003, 60, '包装',     209,  5,  40, 0, 0);

-- ------------------------------------------------------------
-- Production Version
-- ------------------------------------------------------------

INSERT INTO production_version
(
    production_version_id,
    product_id,
    version,
    bom_id,
    routing_id,
    valid_from,
    valid_to,
    min_lot_size,
    max_lot_size
)
VALUES
(3001, 1, '01', 1001, 2001, '2026-01-01', '9999-12-31', 1, 10000),
(3002, 2, '01', 1002, 2002, '2026-01-01', '9999-12-31', 1, 10000),
(3003, 3, '01', 1003, 2003, '2026-01-01', '9999-12-31', 1, 10000);

-- ------------------------------------------------------------
-- Inventory
-- ------------------------------------------------------------

INSERT INTO inventory
(material_id, plant, storage_location, quantity, unit, reserved_quantity)
VALUES
(101, 'PLANT-01', 'RAW-01',  1200,  'KG', 0),
(102, 'PLANT-01', 'RAW-01',   600,  'KG', 0),
(103, 'PLANT-01', 'RAW-01',  1800,  'EA', 0),
(104, 'PLANT-01', 'RAW-01',  1600,  'EA', 0),
(105, 'PLANT-01', 'RAW-01', 10000,  'EA', 0),
(106, 'PLANT-01', 'RAW-01',   700,  'EA', 0),
(107, 'PLANT-01', 'RAW-01',  1200,  'EA', 0),
(108, 'PLANT-01', 'RAW-01',   500,  'EA', 0),
(109, 'PLANT-01', 'RAW-01',   450,  'EA', 0),
(110, 'PLANT-01', 'RAW-01',  1400,  'EA', 0),
(111, 'PLANT-01', 'PACK-01', 2000,  'EA', 0);

-- ------------------------------------------------------------
-- Production Order
-- ------------------------------------------------------------

INSERT INTO production_order
(
    order_id,
    order_code,
    product_id,
    production_version_id,
    quantity,
    release_date,
    due_date,
    priority,
    status
)
VALUES
(4001, 'PO-20260921-001', 1, 3001, 500, '2026-09-21 08:00:00', '2026-09-21 17:00:00', 2, 'RELEASED'),
(4002, 'PO-20260921-002', 2, 3002, 300, '2026-09-21 08:00:00', '2026-09-22 12:00:00', 3, 'RELEASED'),
(4003, 'PO-20260921-003', 3, 3003, 250, '2026-09-21 08:00:00', '2026-09-21 18:00:00', 1, 'RELEASED'),
(4004, 'PO-20260921-004', 1, 3001, 200, '2026-09-21 12:00:00', '2026-09-22 15:00:00', 4, 'CREATED');

-- ------------------------------------------------------------
-- Production Order Operation
-- Copy of routing operations for each production order
-- ------------------------------------------------------------

INSERT INTO production_order_operation
(
    order_id,
    operation_no,
    operation_name,
    work_center_id,
    quantity,
    setup_min,
    process_sec_per_unit,
    planned_start,
    planned_end,
    actual_start,
    actual_end,
    status
)
VALUES
-- Order 4001: KETTLE
(4001, 10, '金属冲压', 201, 500, 20,  30, NULL, NULL, NULL, NULL, 'WAITING'),
(4001, 20, '注塑',     202, 500, 30,  45, NULL, NULL, NULL, NULL, 'WAITING'),
(4001, 30, '点焊',     203, 500, 10,  20, NULL, NULL, NULL, NULL, 'WAITING'),
(4001, 40, '总装',     204, 500, 15,  90, NULL, NULL, NULL, NULL, 'WAITING'),
(4001, 50, '安规测试', 208, 500,  5,  45, NULL, NULL, NULL, NULL, 'WAITING'),
(4001, 60, '包装',     209, 500,  5,  30, NULL, NULL, NULL, NULL, 'WAITING'),

-- Order 4002: TOASTER
(4002, 10, '金属冲压', 201, 300, 25,  40, NULL, NULL, NULL, NULL, 'WAITING'),
(4002, 20, '注塑',     202, 300, 25,  30, NULL, NULL, NULL, NULL, 'WAITING'),
(4002, 30, '点焊',     203, 300, 15,  30, NULL, NULL, NULL, NULL, 'WAITING'),
(4002, 40, '总装',     205, 300, 15, 100, NULL, NULL, NULL, NULL, 'WAITING'),
(4002, 50, '安规测试', 208, 300,  5,  50, NULL, NULL, NULL, NULL, 'WAITING'),
(4002, 60, '包装',     209, 300,  5,  35, NULL, NULL, NULL, NULL, 'WAITING'),

-- Order 4003: RICE COOKER
(4003, 10, '金属冲压', 201, 250, 30,  35, NULL, NULL, NULL, NULL, 'WAITING'),
(4003, 20, '注塑',     202, 250, 30,  60, NULL, NULL, NULL, NULL, 'WAITING'),
(4003, 30, 'PCB测试',  207, 250, 10,  40, NULL, NULL, NULL, NULL, 'WAITING'),
(4003, 40, '总装',     206, 250, 20, 120, NULL, NULL, NULL, NULL, 'WAITING'),
(4003, 50, '安规测试', 208, 250,  5,  60, NULL, NULL, NULL, NULL, 'WAITING'),
(4003, 60, '包装',     209, 250,  5,  40, NULL, NULL, NULL, NULL, 'WAITING'),

-- Order 4004: KETTLE
(4004, 10, '金属冲压', 201, 200, 20,  30, NULL, NULL, NULL, NULL, 'WAITING'),
(4004, 20, '注塑',     202, 200, 30,  45, NULL, NULL, NULL, NULL, 'WAITING'),
(4004, 30, '点焊',     203, 200, 10,  20, NULL, NULL, NULL, NULL, 'WAITING'),
(4004, 40, '总装',     204, 200, 15,  90, NULL, NULL, NULL, NULL, 'WAITING'),
(4004, 50, '安规测试', 208, 200,  5,  45, NULL, NULL, NULL, NULL, 'WAITING'),
(4004, 60, '包装',     209, 200,  5,  30, NULL, NULL, NULL, NULL, 'WAITING');

-- ------------------------------------------------------------
-- Machine Status
-- ------------------------------------------------------------

INSERT INTO machine_status
(work_center_id, status_timestamp, status, available, note)
VALUES
(201, '2026-09-21 08:00:00', 'RUNNING', TRUE,  NULL),
(202, '2026-09-21 08:00:00', 'RUNNING', TRUE,  NULL),
(203, '2026-09-21 08:00:00', 'RUNNING', TRUE,  NULL),
(204, '2026-09-21 08:00:00', 'RUNNING', TRUE,  NULL),
(205, '2026-09-21 08:00:00', 'RUNNING', TRUE,  NULL),
(206, '2026-09-21 08:00:00', 'RUNNING', TRUE,  NULL),
(207, '2026-09-21 08:00:00', 'RUNNING', TRUE,  NULL),
(208, '2026-09-21 08:00:00', 'RUNNING', TRUE,  NULL),
(209, '2026-09-21 08:00:00', 'RUNNING', TRUE,  NULL),

-- Example breakdown event
(201, '2026-09-21 11:20:00', 'BREAKDOWN', FALSE, 'PRESS-01 breakdown event');

-- ============================================================
-- Useful Queries
-- ============================================================

-- 1. BOM explosion for one product
-- Example: KETTLE-001
SELECT
    p.material_code AS product_code,
    c.material_code AS component_code,
    c.description   AS component_description,
    bi.quantity,
    bi.unit
FROM bom_header bh
JOIN material p
  ON p.material_id = bh.product_id
JOIN bom_item bi
  ON bi.bom_id = bh.bom_id
JOIN material c
  ON c.material_id = bi.component_id
WHERE p.material_code = 'KETTLE-001'
ORDER BY bi.item_no;

-- 2. Routing for one product
SELECT
    p.material_code AS product_code,
    ro.operation_no,
    ro.operation_name,
    wc.work_center_code,
    ro.setup_min,
    ro.process_sec_per_unit
FROM routing_header rh
JOIN material p
  ON p.material_id = rh.product_id
JOIN routing_operation ro
  ON ro.routing_id = rh.routing_id
JOIN work_center wc
  ON wc.work_center_id = ro.work_center_id
WHERE p.material_code = 'KETTLE-001'
ORDER BY ro.operation_no;

-- 3. Raw-material competition:
-- Which products consume the same component?
SELECT
    c.material_code AS component_code,
    COUNT(DISTINCT bh.product_id) AS product_count,
    GROUP_CONCAT(
        DISTINCT p.material_code
        ORDER BY p.material_code
        SEPARATOR ', '
    ) AS competing_products
FROM bom_item bi
JOIN bom_header bh
  ON bh.bom_id = bi.bom_id
JOIN material p
  ON p.material_id = bh.product_id
JOIN material c
  ON c.material_id = bi.component_id
GROUP BY c.material_id, c.material_code
HAVING COUNT(DISTINCT bh.product_id) > 1
ORDER BY product_count DESC, component_code;

-- 4. Machine competition:
-- Which products share the same Work Center?
SELECT
    wc.work_center_code,
    COUNT(DISTINCT rh.product_id) AS product_count,
    GROUP_CONCAT(
        DISTINCT p.material_code
        ORDER BY p.material_code
        SEPARATOR ', '
    ) AS competing_products
FROM routing_operation ro
JOIN routing_header rh
  ON rh.routing_id = ro.routing_id
JOIN material p
  ON p.material_id = rh.product_id
JOIN work_center wc
  ON wc.work_center_id = ro.work_center_id
GROUP BY wc.work_center_id, wc.work_center_code
HAVING COUNT(DISTINCT rh.product_id) > 1
ORDER BY product_count DESC, wc.work_center_code;

-- 5. Material requirement for all released production orders
SELECT
    c.material_code AS component_code,
    c.description,
    SUM(po.quantity * bi.quantity * (1 + bi.scrap_rate)) AS total_required,
    bi.unit
FROM production_order po
JOIN production_version pv
  ON pv.production_version_id = po.production_version_id
JOIN bom_item bi
  ON bi.bom_id = pv.bom_id
JOIN material c
  ON c.material_id = bi.component_id
WHERE po.status IN ('RELEASED', 'IN_PROCESS')
GROUP BY c.material_id, c.material_code, c.description, bi.unit
ORDER BY c.material_code;

-- 6. Compare required material with current inventory
SELECT
    req.material_code,
    req.total_required,
    COALESCE(inv.total_inventory, 0) AS total_inventory,
    COALESCE(inv.total_inventory, 0) - req.total_required AS balance_after_orders
FROM (
    SELECT
        c.material_id,
        c.material_code,
        SUM(po.quantity * bi.quantity * (1 + bi.scrap_rate)) AS total_required
    FROM production_order po
    JOIN production_version pv
      ON pv.production_version_id = po.production_version_id
    JOIN bom_item bi
      ON bi.bom_id = pv.bom_id
    JOIN material c
      ON c.material_id = bi.component_id
    WHERE po.status IN ('RELEASED', 'IN_PROCESS')
    GROUP BY c.material_id, c.material_code
) req
LEFT JOIN (
    SELECT
        material_id,
        SUM(quantity - reserved_quantity) AS total_inventory
    FROM inventory
    GROUP BY material_id
) inv
  ON inv.material_id = req.material_id
ORDER BY req.material_code;

-- 7. Estimate processing duration for order operations
SELECT
    poo.order_id,
    po.order_code,
    poo.operation_no,
    poo.operation_name,
    wc.work_center_code,
    poo.setup_min,
    poo.quantity,
    poo.process_sec_per_unit,
    ROUND(
        poo.setup_min
        + (poo.quantity * poo.process_sec_per_unit / 60.0),
        2
    ) AS estimated_total_minutes
FROM production_order_operation poo
JOIN production_order po
  ON po.order_id = poo.order_id
JOIN work_center wc
  ON wc.work_center_id = poo.work_center_id
ORDER BY poo.order_id, poo.operation_no;

-- ============================================================
-- End of file
-- ============================================================
