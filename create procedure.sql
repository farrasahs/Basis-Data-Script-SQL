-- ================================
-- 1. Buat Database
-- ================================
DROP TABLE IF EXISTS inventory_movements;
CREATE TABLE inventory_movements (
  movement_id INT AUTO_INCREMENT PRIMARY KEY,
  material_id INT NOT NULL,
  movement_type ENUM('in','out','adjust') NOT NULL,
  qty DECIMAL(18,4) NOT NULL,
  reference VARCHAR(100),
  note TEXT,
  moved_by INT,
  moved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_im_material FOREIGN KEY (material_id) REFERENCES materials(material_id),
  CONSTRAINT fk_im_user FOREIGN KEY (moved_by) REFERENCES users(user_id)
);

DROP TABLE IF EXISTS finished_inventory;
CREATE TABLE finished_inventory (
  inventory_id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  qty DECIMAL(18,4) DEFAULT 0,
  last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_fi_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE INDEX idx_products_code ON products(product_code);


CREATE DATABASE IF NOT EXISTS sim_produksi CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sim_produksi;

-- ================================
-- 2. Tabel master & referensi
-- ================================
CREATE TABLE IF NOT EXISTS users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  full_name VARCHAR(100),
  role VARCHAR(30),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS roles (
  role_id INT AUTO_INCREMENT PRIMARY KEY,
  role_name VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS employees (
  employee_id INT AUTO_INCREMENT PRIMARY KEY,
  nik VARCHAR(30) UNIQUE,
  name VARCHAR(100) NOT NULL,
  position VARCHAR(100),
  phone VARCHAR(30),
  email VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS machines (
  machine_id INT AUTO_INCREMENT PRIMARY KEY,
  machine_code VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(100) NOT NULL,
  location VARCHAR(100),
  status ENUM('idle','running','maintenance','broken') DEFAULT 'idle',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS materials (
  material_id INT AUTO_INCREMENT PRIMARY KEY,
  material_code VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(150) NOT NULL,
  unit VARCHAR(20) NOT NULL,
  stock DECIMAL(18,4) DEFAULT 0,
  min_stock DECIMAL(18,4) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  product_code VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(150) NOT NULL,
  unit VARCHAR(20) NOT NULL,
  price DECIMAL(18,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bill of Materials (BOM)
CREATE TABLE IF NOT EXISTS product_materials (
  id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  material_id INT NOT NULL,
  qty_needed DECIMAL(18,4) NOT NULL,
  CONSTRAINT fk_pm_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  CONSTRAINT fk_pm_material FOREIGN KEY (material_id) REFERENCES materials(material_id) ON DELETE CASCADE
);

-- ================================
-- 3. Tabel produksi / transaksi
-- ================================
CREATE TABLE IF NOT EXISTS production_orders (
  production_id INT AUTO_INCREMENT PRIMARY KEY,
  production_code VARCHAR(50) NOT NULL UNIQUE,
  product_id INT NOT NULL,
  quantity_order DECIMAL(18,4) NOT NULL,
  quantity_produced DECIMAL(18,4) DEFAULT 0,
  status ENUM('planned','in_progress','completed','cancelled') DEFAULT 'planned',
  scheduled_date DATE,
  start_at DATETIME NULL,
  finish_at DATETIME NULL,
  created_by INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_po_product FOREIGN KEY (product_id) REFERENCES products(product_id),
  CONSTRAINT fk_po_user FOREIGN KEY (created_by) REFERENCES users(user_id)
);

CREATE TABLE IF NOT EXISTS production_details (
  detail_id INT AUTO_INCREMENT PRIMARY KEY,
  production_id INT NOT NULL,
  machine_id INT,
  employee_id INT,
  operation VARCHAR(255),
  qty_done DECIMAL(18,4) DEFAULT 0,
  note TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_pd_production FOREIGN KEY (production_id) REFERENCES production_orders(production_id) ON DELETE CASCADE,
  CONSTRAINT fk_pd_machine FOREIGN KEY (machine_id) REFERENCES machines(machine_id),
  CONSTRAINT fk_pd_employee FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Inventory movements (for materials)
CREATE TABLE IF NOT EXISTS inventory_movements (
  movement_id INT AUTO_INCREMENT PRIMARY KEY,
  material_id INT NOT NULL,
  movement_type ENUM('in','out','adjust') NOT NULL,
  qty DECIMAL(18,4) NOT NULL,
  reference VARCHAR(100),
  note TEXT,
  moved_by INT,
  moved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_im_material FOREIGN KEY (material_id) REFERENCES materials(material_id),
  CONSTRAINT fk_im_user FOREIGN KEY (moved_by) REFERENCES users(user_id)
);

-- Finished goods inventory
CREATE TABLE IF NOT EXISTS finished_inventory (
  inventory_id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  qty DECIMAL(18,4) DEFAULT 0,
  last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_fi_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ================================
-- 4. Index & sample constraints
-- ================================
-- Cek dan hapus index lama secara manual
SET @index_exists := (
  SELECT COUNT(*)
  FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'products'
    AND index_name = 'idx_products_code'
);

SET @sql := IF(@index_exists > 0, 'DROP INDEX idx_products_code ON products;', 'SELECT "Index not found"');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ================================
-- 5. Sample data (opsional) — ganti sesuai kebutuhan
-- ================================
INSERT INTO roles (role_name, description) VALUES
('admin','Administrator sistem'),
('planner','Production planner'),
('operator','Machine operator');

INSERT INTO users (username, password_hash, full_name, role) VALUES
('admin','<hash_here>','Administrator','admin'),
('planner1','<hash_here>','Planner Satu','planner'),
('operator1','<hash_here>','Operator Satu','operator');

INSERT INTO employees (nik, name, position, phone) VALUES
('EMP001','Budi Santoso','Operator','081234567890'),
('EMP002','Siti Nur','Supervisor','081298765432');

INSERT INTO machines (machine_code, name, location) VALUES
('MC-001','Mesin Press A','Line 1'),
('MC-002','Mesin Cutter B','Line 2');

INSERT INTO materials (material_code, name, unit, stock, min_stock) VALUES
('MAT-001','Bahan A','kg',1000,50),
('MAT-002','Bahan B','liter',500,20);

INSERT INTO products (product_code, name, unit, price) VALUES
('PRD-001','Produk X','pcs',25000),
('PRD-002','Produk Y','pcs',40000);

-- contoh BOM: Produk X butuh Bahan A 2 kg, Bahan B 0.5 liter
INSERT INTO product_materials (product_id, material_id, qty_needed)
VALUES
((SELECT product_id FROM products WHERE product_code='PRD-001'),
 (SELECT material_id FROM materials WHERE material_code='MAT-001'),
 2),
((SELECT product_id FROM products WHERE product_code='PRD-001'),
 (SELECT material_id FROM materials WHERE material_code='MAT-002'),
 0.5);

-- ================================
-- 6. Views berguna
-- ================================
CREATE OR REPLACE VIEW vw_production_summary AS
SELECT p.production_id, p.production_code, pr.product_code, pr.name AS product_name,
       p.quantity_order, p.quantity_produced, p.status, p.scheduled_date, p.created_at
FROM production_orders p
JOIN products pr ON p.product_id = pr.product_id;

CREATE OR REPLACE VIEW vw_material_stock AS
SELECT m.material_id, m.material_code, m.name, m.unit, m.stock, m.min_stock,
       COALESCE(SUM(im.qty * CASE WHEN im.movement_type='in' THEN 1 WHEN im.movement_type='out' THEN -1 ELSE 0 END),0) AS movement_calculated
FROM materials m
LEFT JOIN inventory_movements im ON m.material_id = im.material_id
GROUP BY m.material_id;

-- ================================
-- 7. TRIGGER contoh: update materials.stock saat inventory_movements
-- ================================
DELIMITER $$
CREATE TRIGGER trg_after_inventory_ins
AFTER INSERT ON inventory_movements
FOR EACH ROW
BEGIN
  IF NEW.movement_type = 'in' THEN
    UPDATE materials SET stock = stock + NEW.qty WHERE material_id = NEW.material_id;
  ELSEIF NEW.movement_type = 'out' THEN
    UPDATE materials SET stock = stock - NEW.qty WHERE material_id = NEW.material_id;
  ELSE
    -- adjust: set absolute value (optional behavior, here we'll add)
    UPDATE materials SET stock = stock + NEW.qty WHERE material_id = NEW.material_id;
  END IF;
END$$
DELIMITER ;

-- ================================
-- 8. STORED PROCEDURES
--    a) Buat production order (cek BOM & stock minimal)
-- ================================
DELIMITER $$
CREATE PROCEDURE sp_create_production_order (
  IN p_prod_code VARCHAR(50),
  IN p_qty DECIMAL(18,4),
  IN p_creator INT,
  OUT p_result VARCHAR(200)
)
BEGIN
  DECLARE v_product_id INT;
  DECLARE v_material_id INT;
  DECLARE v_qty_needed DECIMAL(18,4);
  DECLARE v_available DECIMAL(18,4);
  DECLARE done INT DEFAULT 0;

  -- check product exists
  SELECT product_id INTO v_product_id FROM products WHERE product_code = p_prod_code LIMIT 1;
  IF v_product_id IS NULL THEN
    SET p_result = CONCAT('ERROR: Produk ', p_prod_code, ' tidak ditemukan');
    LEAVE sp_create_production_order;
  END IF;

  -- cursor to check each BOM material
  

  DECLARE cur_bom CURSOR FOR
    SELECT material_id, qty_needed FROM product_materials WHERE product_id = v_product_id;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

  OPEN cur_bom;
  read_loop: LOOP
    FETCH cur_bom INTO v_material_id, v_qty_needed;
    IF done = 1 THEN
      LEAVE read_loop;
    END IF;
    SET v_available = (SELECT stock FROM materials WHERE material_id = v_material_id);
    IF v_available < (v_qty_needed * p_qty) THEN
      SET p_result = CONCAT('INSUFFICIENT_MATERIAL: material_id=', v_material_id, ' butuh=', v_qty_needed*p_qty, ' stok=', v_available);
      CLOSE cur_bom;
      LEAVE sp_create_production_order;
    END IF;
  END LOOP;
  CLOSE cur_bom;

  -- jika semua cukup, buat production order
  INSERT INTO production_orders (production_code, product_id, quantity_order, created_by, status, scheduled_date)
  VALUES (CONCAT('PO-', DATE_FORMAT(NOW(),'%Y%m%d%H%i%s')), v_product_id, p_qty, p_creator, 'planned', CURDATE());

  SET p_result = 'OK';
END$$
DELIMITER ;

-- ================================
--    b) Mark production complete dan update inventory finished goods + kurangi bahan
-- ================================
DELIMITER $$
CREATE PROCEDURE sp_complete_production (
  IN p_production_code VARCHAR(50),
  IN p_qty_produced DECIMAL(18,4),
  IN p_user INT,
  OUT p_result VARCHAR(200)
)
BEGIN
  DECLARE v_production_id INT;
  DECLARE v_product_id INT;
  DECLARE v_order_qty DECIMAL(18,4);

  SELECT production_id, product_id, quantity_order INTO v_production_id, v_product_id, v_order_qty
  FROM production_orders WHERE production_code = p_production_code LIMIT 1;

  IF v_production_id IS NULL THEN
    SET p_result = CONCAT('ERROR: production_code ', p_production_code, ' tidak ditemukan');
    LEAVE sp_complete_production;
  END IF;

  -- update production_orders
  UPDATE production_orders
  SET quantity_produced = quantity_produced + p_qty_produced,
      status = IF(quantity_produced + p_qty_produced >= quantity_order,'completed','in_progress'),
      finish_at = IF(quantity_produced + p_qty_produced >= quantity_order, NOW(), NULL)
  WHERE production_id = v_production_id;

  -- masukkan finished goods
  INSERT INTO finished_inventory (product_id, qty)
  VALUES (v_product_id, p_qty_produced)
  ON DUPLICATE KEY UPDATE qty = qty + p_qty_produced, last_update = NOW();

  -- keluarkan material berdasarkan BOM (kurangi stock dan catat movement)
  DECLARE v_material_id INT;
  DECLARE v_qty_needed DECIMAL(18,4);
  DECLARE bom_done INT DEFAULT 0;
  DECLARE cur_bom2 CURSOR FOR
    SELECT material_id, qty_needed FROM product_materials WHERE product_id = v_product_id;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET bom_done = 1;

  OPEN cur_bom2;
  bom_loop: LOOP
    FETCH cur_bom2 INTO v_material_id, v_qty_needed;
    IF bom_done = 1 THEN
      LEAVE bom_loop;
    END IF;

    -- insert movement out
    INSERT INTO inventory_movements (material_id, movement_type, qty, reference, note, moved_by)
    VALUES (v_material_id, 'out', v_qty_needed * p_qty_produced, p_production_code, 'Consume for production', p_user);

    -- stock update otomatis via trigger trg_after_inventory_ins
  END LOOP;
  CLOSE cur_bom2;

  SET p_result = 'OK';
END$$
DELIMITER ;

-- ================================
-- 9. Procedure bantu: Get production by date range
-- ================================
DELIMITER $$
CREATE PROCEDURE sp_get_production_by_date (
  IN p_from DATE,
  IN p_to DATE
)
BEGIN
  SELECT p.production_code, pr.product_code, pr.name AS product_name,
         p.quantity_order, p.quantity_produced, p.status, p.scheduled_date
  FROM production_orders p
  JOIN products pr ON p.product_id = pr.product_id
  WHERE p.scheduled_date BETWEEN p_from AND p_to
  ORDER BY p.scheduled_date;
END$$
DELIMITER ;

-- ================================
-- 10. Procedure update stock manual (adjust)
-- ================================
DELIMITER $$
CREATE PROCEDURE sp_adjust_material_stock (
  IN p_material_code VARCHAR(50),
  IN p_qty DECIMAL(18,4),
  IN p_type ENUM('in','out','adjust'),
  IN p_user INT,
  IN p_ref VARCHAR(100)
)
BEGIN
  DECLARE v_material_id INT;
  SELECT material_id INTO v_material_id FROM materials WHERE material_code = p_material_code LIMIT 1;
  IF v_material_id IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Material tidak ditemukan';
  END IF;

  INSERT INTO inventory_movements (material_id, movement_type, qty, reference, note, moved_by)
  VALUES (v_material_id, p_type, p_qty, p_ref, 'Manual adjustment', p_user);
END$$
DELIMITER ;
