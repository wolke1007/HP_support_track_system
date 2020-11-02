# create table command
CREATE TABLE past_delivery_data (
    serial INTEGER, 
    model TEXT, 
    HP_case_id TEXT, 
    company_name TEXT,
    order_date INTEGER,
    arrive_date INTEGER,
    goods_receiver_name TEXT,
    address TEXT,
    goods_receiver_phone TEXT,
    goods_name TEXT,
    quantity INTEGER,
    remark TEXT, goods_type TEXT, unamed TEXT
)

CREATE TABLE deliver_status (
    last_update_date TEXT,
    serial_number TEXT,
    goods_type TEXT,
	goods_name TEXT,
    need_refill INTEGER DEFAULT 0,
	need_refill_count INTEGER DEFAULT 0,
    PRIMARY KEY(serial_number, goods_type)
)

CREATE TABLE product_level (
    last_update_date TEXT,
    serial_number TEXT,
    goods_type TEXT,
    product_level INTEGER,
    PRIMARY KEY(serial_number, goods_type)
)

CREATE TABLE consumable_levels (
    `Report Content DateTime` TEXT,
    `Customer Name` TEXT,
    `Country` TEXT,
    `Region` TEXT,
    `Site` TEXT,
    `Building` TEXT,
    `Level` INTEGER,
    `Product Model Name` TEXT,
    `Asset Number` TEXT,
    `Serial Number` TEXT,
    `Usage Count Date` TEXT,
    `Black Level` INTEGER,
    `Cyan Level` INTEGER,
    `Magenta Level` INTEGER,
    `Yellow Level` INTEGER,
    `Light Cyan Level` INTEGER,
    `Light Magenta Level` INTEGER,
    `Tri-Color Level` INTEGER,
    `Bonding Agent Level` INTEGER,
    `Staple Level` INTEGER,
    `Staple Second Level` INTEGER,
    `Staple Third Level` INTEGER,
    `Cyan Drum Level` INTEGER,
    `Yellow Drum Level` INTEGER,
    `Magenta Drum Level` INTEGER,
    `Black Drum Level` INTEGER,
    `Drum Kit Level` INTEGER,
    `Transfer Kit Level` INTEGER,
    `Fuser Kit Level` INTEGER,
    `Cleaning Kit Level` INTEGER,
    `Maintenance Combo Kit Level` INTEGER,
    `Document Feeder Kit Level` INTEGER,
    `Roller Level` INTEGER,
    `Grey Level` INTEGER,
    `Light Grey Level` INTEGER,
    `Photo Black Level` INTEGER,
    `Matte Black Level` INTEGER,
    `Red Level` INTEGER,
    `Green Level` INTEGER,
    `Blue Level` INTEGER,
    `Gloss Enhancer Level` INTEGER,
    `Pen Wipe Level` INTEGER,
    `Collection Unit Level` INTEGER,
    `Black Developer Maintenance Level` INTEGER,
    `Cyan Developer Maintenance Level` INTEGER,
    `Magenta Developer Maintenance Level` INTEGER,
    `Yellow Developer Maintenance Level` INTEGER,
    PRIMARY KEY(`Report Content DateTime`, `Serial Number`)
)

# [做成VIEW] 建立需要派送的清單
CREATE VIEW need_deliver_report AS SELECT DISTINCT
    c.`Product Model Name` AS '機型',
    d.serial_number AS '序號',
    c.`Asset Number` AS '資產編號',
    MAX(d.goods_name) AS '品項',
    d.goods_type AS '品名',
    c.`Site` AS '所在地',
    c.`Region` AS '地區',
    c.`Customer Name` AS '客戶',
    c.`Building` AS '所屬大樓',
    c.`Level` AS '樓層',
    c.`Usage Count Date` AS '最後用量資訊收集時間'
FROM consumable_levels AS c
JOIN deliver_status AS d ON d.serial_number = c.`Serial Number`
WHERE d.need_refill = 1 AND d.need_refill_count = 0
GROUP BY d.serial_number, d.goods_type;

# 用已知的 goods_type 去填補 past_delivery_data 中 goods_type 為 NULL 的欄位
UPDATE
	past_delivery_data
SET
	goods_type = (
	SELECT
		goods_type
	FROM
		(
		SELECT
			goods_type, goods_name
		FROM
			past_delivery_data
		WHERE
			goods_type IS NOT NULL
		group by
			goods_name)
	WHERE
		goods_name = past_delivery_data.goods_name )
WHERE
	goods_type IS NULL

# 更新 deliver_status 指定 序號 機器的指定 品項 的 need_refill 與 need_refill_count 值
# 這邊的邏輯是 need_refill 如果是需要

# [INSERT deliver_status] 若不存在此序號機器，新增至 deliver_status
INSERT OR IGNORE INTO deliver_status 
SELECT
	DATE('NOW') AS last_update_date,
	c."Serial Number" AS serial_number,
	'黑' AS 'goods_type',
	(SELECT goods_name FROM past_delivery_data WHERE "serial" = c."Serial Number" AND goods_type = '黑') AS goods_name,
	0 need_refill,
	0 need_refill_count
FROM
	consumable_levels AS c
WHERE "Black Level" != 'N/A'

# [UPDATE deliver_status] 判斷該序號機器是否需要派送並更新狀態
UPDATE deliver_status SET
	last_update_date = DATE('NOW'),
	need_refill = CASE WHEN (SELECT "Black Level" FROM consumable_levels WHERE serial_number = 'CNB1KCM22C') <= 29 THEN 1 ELSE 0 END,
	need_refill_count = CASE WHEN need_refill = 1 THEN need_refill_count + 1 ELSE need_refill END
WHERE serial_number = 'CNB1KCM22C'
AND goods_type = '黑'

# [REPLACE product_level] 更新所有的應該追蹤的產品的用量
REPLACE INTO product_level 
SELECT
	DATE('NOW') AS last_update_date,
	c."Serial Number" AS serial_number,
	'黑' AS 'goods_type',
	CASE WHEN "Black Level" >= 0 THEN "Black Level" ELSE 'N/A' END product_level
FROM
	consumable_levels AS c
WHERE "Black Level" != 'N/A'





==========廢棄邏輯=========
# 將過去有的資訊剔除，只找出 past_delivery 中新出現的資料，之後需要 insert or replace 至 deliver_status 中
REPLACE INTO deliver_status 
SELECT
	DATE('NOW') AS last_update_date,
	c."Serial Number" AS serial_number,
	'黑' AS 'goods_type',
	CASE WHEN "Black Level" >= 0 THEN "Black Level" ELSE 'N/A' END product_level,
	CASE WHEN "Black Level" <= 30 
	AND (SELECT need_refill FROM deliver_status AS d WHERE c."Serial Number" = d.serial_number and goods_type = d.goods_type) = 0 
	AND "Black Level" - (SELECT product_level FROM deliver_status AS d WHERE c."Serial Number" = d.serial_number and goods_type = d.goods_type) < 0
	THEN 1 ELSE 0 END 'need_refill'
FROM
	consumable_levels as c
WHERE "Black Level" != 'N/A'

# 尋找某個序號的最後配送時間及配送的產品
SELECT
	serial,
	DATE(substr(arrive_date , 1, 10)) last_deliver_date,
	goods_name,
	goods_type
FROM
	past_delivery_data
WHERE
	serial = 'AABBCC'
ORDER BY
	last_deliver_date
DESC
LIMIT 1

# 刪除 VIEW
DROP VIEW IF EXISTS two_days_level_diff;

# 昨天的紀錄
SELECT *, DATE(substr(`Report Content DateTime`, 7, 4) ||
	'-' ||
	substr(`Report Content DateTime`, 1, 2) ||
	'-' ||
	substr(`Report Content DateTime`, 4, 2)
	)  as 'datetime'
FROM consumable_levels WHERE datetime = DATE('NOW','-1 DAY')

# 查詢所有需要被關注又有數據的品項
SELECT
	DATE('NOW') AS last_update_date,
	c."Serial Number" AS serial_number,
	'黑' AS 'goods_type',
	CASE WHEN "Black Level" >= 0	THEN "Black Level" ELSE 'N/A' END product_level
FROM
	consumable_levels as c
WHERE "Black Level" != 'N/A'
-- UNION ALL
-- SELECT
-- 	DATE('NOW') AS last_update_date,
-- 	c."Serial Number" AS serial_number,
-- 	'藍' AS 'goods_type',
-- 	CASE WHEN "Cyan Level" >= 0	THEN "Cyan Level" ELSE 'N/A' END product_level,
-- 	0 need_deliver
-- FROM
-- 	consumable_levels as c
-- WHERE product_level != 'N/A'
-- UNION ALL
-- SELECT
-- 	DATE('NOW') AS last_update_date,
-- 	c."Serial Number" AS serial_number,
-- 	'紅' AS 'goods_type',
-- 	CASE WHEN "Magenta Level" >= 0	THEN "Magenta Level" ELSE 'N/A' END product_level,
-- 	0 need_deliver
-- FROM
-- 	consumable_levels as c
-- WHERE product_level != 'N/A'
-- UNION ALL
-- SELECT
-- 	DATE('NOW') AS last_update_date,
-- 	c."Serial Number" AS serial_number,
-- 	'黃' AS 'goods_type',
-- 	CASE WHEN "Yellow Level" >= 0	THEN "Yellow Level" ELSE 'N/A' END product_level,
-- 	0 need_deliver
-- FROM
-- 	consumable_levels as c
-- WHERE product_level != 'N/A'
-- UNION ALL
-- SELECT
-- 	DATE('NOW') AS last_update_date,
-- 	c."Serial Number" AS serial_number,
-- 	'黑鼓' AS 'goods_type',
-- 	CASE WHEN "Black Drum Level" >= 0	THEN "Black Drum Level" ELSE 'N/A' END product_level,
-- 	0 need_deliver
-- FROM
-- 	consumable_levels as c
-- WHERE product_level != 'N/A'
-- UNION ALL
-- SELECT
-- 	DATE('NOW') AS last_update_date,
-- 	c."Serial Number" AS serial_number,
-- 	'藍鼓' AS 'goods_type',
-- 	CASE WHEN "Cyan Drum Level" >= 0	THEN "Cyan Drum Level" ELSE 'N/A' END product_level,
-- 	0 need_deliver
-- FROM
-- 	consumable_levels as c
-- WHERE product_level != 'N/A'
-- UNION ALL
-- SELECT
-- 	DATE('NOW') AS last_update_date,
-- 	c."Serial Number" AS serial_number,
-- 	'紅鼓' AS 'goods_type',
-- 	CASE WHEN "Magenta Drum Level" >= 0	THEN "Magenta Drum Level" ELSE 'N/A' END product_level,
-- 	0 need_deliver
-- FROM
-- 	consumable_levels as c
-- WHERE product_level != 'N/A'
-- UNION ALL
-- SELECT
-- 	DATE('NOW') AS last_update_date,
-- 	c."Serial Number" AS serial_number,
-- 	'黃鼓' AS 'goods_type',
-- 	CASE WHEN "Yellow Drum Level" >= 0	THEN "Yellow Drum Level" ELSE 'N/A' END product_level,
-- 	0 need_deliver
-- FROM
-- 	consumable_levels as c
-- WHERE product_level != 'N/A'
-- UNION ALL
-- SELECT
-- 	DATE('NOW') AS last_update_date,
-- 	c."Serial Number" AS serial_number,
-- 	'Drum Kit' AS 'goods_type',
-- 	CASE WHEN "Drum Kit Level" >= 0	THEN "Drum Kit Level" ELSE 'N/A' END product_level,
-- 	0 need_deliver
-- FROM
-- 	consumable_levels as c
-- WHERE product_level != 'N/A'
-- UNION ALL
-- SELECT
-- 	DATE('NOW') AS last_update_date,
-- 	c."Serial Number" AS serial_number,
-- 	'Transfer Kit' AS 'goods_type',
-- 	CASE WHEN "Transfer Kit Level" >= 0	THEN "Transfer Kit Level" ELSE 'N/A' END product_level,
-- 	0 need_deliver
-- FROM
-- 	consumable_levels as c
-- WHERE product_level != 'N/A'
-- UNION ALL
-- SELECT
-- 	DATE('NOW') AS last_update_date,
-- 	c."Serial Number" AS serial_number,
-- 	'Fuser Kit' AS 'goods_type',
-- 	CASE WHEN "Fuser Kit Level" >= 0 THEN "Fuser Kit Level" ELSE 'N/A' END product_level,
-- 	0 need_deliver
-- FROM
-- 	consumable_levels as c
-- WHERE product_level != 'N/A'
-- UNION ALL
-- SELECT
-- 	DATE('NOW') AS last_update_date,
-- 	c."Serial Number" AS serial_number,
-- 	'Cleaning Kit' AS 'goods_type',
-- 	CASE WHEN "Cleaning Kit Level" >= 0 THEN "Cleaning Kit Level" ELSE 'N/A' END product_level,
-- 	0 need_deliver
-- FROM
-- 	consumable_levels as c
-- WHERE product_level != 'N/A'
-- UNION ALL
-- SELECT
-- 	DATE('NOW') AS last_update_date,
-- 	c."Serial Number" AS serial_number,
-- 	'Maintenance Combo Kit' AS 'goods_type',
-- 	CASE WHEN "Maintenance Combo Kit Level" >= 0 THEN "Maintenance Combo Kit Level" ELSE 'N/A' END product_level,
-- 	0 need_deliver
-- FROM
-- 	consumable_levels as c
-- WHERE product_level != 'N/A'
-- UNION ALL
-- SELECT
-- 	DATE('NOW') AS last_update_date,
-- 	c."Serial Number" AS serial_number,
-- 	'Document Feeder Kit' AS 'goods_type',
-- 	CASE WHEN "Document Feeder Kit Level" >= 0 THEN "Document Feeder Kit Level" ELSE 'N/A' END product_level,
-- 	0 need_deliver
-- FROM
-- 	consumable_levels as c
-- WHERE product_level != 'N/A'
-- UNION ALL
-- SELECT
-- 	DATE('NOW') AS last_update_date,
-- 	c."Serial Number" AS serial_number,
-- 	'Roller' AS 'goods_type',
-- 	CASE WHEN "Roller Level" >= 0 THEN "Roller Level" ELSE 'N/A' END product_level,
-- 	0 need_deliver
-- FROM
-- 	consumable_levels as c
-- WHERE product_level != 'N/A'