--1️⃣ Foreign Key Indexes (Fast Star Joins)
CREATE INDEX IF NOT EXISTS idx_fact_order_date
ON warehouse.fact_order_items (order_date_id);

--2️⃣ Date Index (Time-Based Analysis)
CREATE INDEX IF NOT EXISTS idx_fact_order_date
ON warehouse.fact_order_items (order_date_id);

--3️⃣ Composite Index (Date + Product)
CREATE INDEX IF NOT EXISTS idx_fact_date_product
ON warehouse.fact_order_items (order_date_id, product_key);

--4️⃣ Business Filter Indexes
CREATE INDEX IF NOT EXISTS idx_fact_order_status
ON warehouse.fact_order_items (order_status);

CREATE INDEX IF NOT EXISTS idx_fact_delivery_status
ON warehouse.fact_order_items (delivery_status);

CREATE INDEX IF NOT EXISTS idx_fact_payment_type
ON warehouse.fact_order_items (payment_type);

CREATE INDEX IF NOT EXISTS idx_fact_market
ON warehouse.fact_order_items (market);

--5️⃣ BRIN Index (Large-Scale Optimization)
CREATE INDEX IF NOT EXISTS brin_fact_order_date
ON warehouse.fact_order_items
USING BRIN (order_date_id);

--6️⃣ Validate Partition Pruning (VERY IMPORTANT)
EXPLAIN
SELECT *
FROM warehouse.fact_order_items
WHERE order_date_id BETWEEN '2017-01-01' AND '2017-12-31';
