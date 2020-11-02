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

# 昨天的紀錄
select *, DATE(substr(`Report Content DateTime`, 7, 4) ||
	'-' ||
	substr(`Report Content DateTime`, 1, 2) ||
	'-' ||
	substr(`Report Content DateTime`, 4, 2)
	)  as 'datetime'
from consumable_levels where datetime = DATE('NOW','-1 DAY')

# [嘗試][做成VIEW][可能有效能問題] 
# 撈出比前一天(範例中以2020-10-28為基準，往前算一天) level 要小(表示有使用)或低於閥值(範例中為30)的顏色，若數值沒變動則設為 N/A
CREATE VIEW two_days_level_diff AS 
select
	*
from
	(
	select
		DISTINCT today.`Serial Number`, today.datetime,
		case
			when yesterday.`Black Level` - today.`Black Level` >= 1
            and today.`Black Level` <= {level_threshold} - 1 
			or yesterday.`Black Level` = 0
            then today.`Black Level`
			else 'N/A'
		END `Black Level`,
		case
			when yesterday.`Cyan Level` - today.`Cyan Level` >= 1 
            and today.`Cyan Level` <= {level_threshold} - 1
			or yesterday.`Cyan Level` = 0
            then today.`Cyan Level`
			else 'N/A'
		END `Cyan Level`,
		case
			when yesterday.`Magenta Level` - today.`Magenta Level` >= 1 
            and today.`Magenta Level` <= {level_threshold} - 1
			or yesterday.`Magenta Level` = 0
            then today.`Magenta Level`
			else 'N/A'
		END `Magenta Level`,
		case
			when yesterday.`Cyan Drum Level` - today.`Cyan Drum Level` >= 1 
            and today.`Cyan Drum Level` <= {level_threshold} - 1
			or yesterday.`Cyan Drum Level` = 0
            then today.`Cyan Drum Level`
			else 'N/A'
		END `Cyan Drum Level`,
		case
			when yesterday.`Yellow Drum Level` - today.`Yellow Drum Level` >= 1 
            and today.`Yellow Drum Level` <= {level_threshold} - 1
            or yesterday.`Yellow Drum Level` = 0
            then today.`Yellow Drum Level`
			else 'N/A'
		END `Yellow Drum Level`,
		case
			when yesterday.`Magenta Drum Level` - today.`Magenta Drum Level` >= 1 
            and today.`Magenta Drum Level` <= {level_threshold} - 1
            or yesterday.`Magenta Drum Level` = 0
            then today.`Magenta Drum Level`
			else 'N/A'
		END `Magenta Drum Level`,
		case
			when yesterday.`Black Drum Level` - today.`Black Drum Level` >= 1 
            and today.`Black Drum Level` <= {level_threshold} - 1
            or yesterday.`Black Drum Level` = 0
            then today.`Black Drum Level`
			else 'N/A'
		END `Black Drum Level`,
		case
			when yesterday.`Drum Kit Level` - today.`Drum Kit Level` >= 1 
            and today.`Drum Kit Level` <= {level_threshold} - 1
            or yesterday.`Drum Kit Level` = 0
            then today.`Drum Kit Level`
			else 'N/A'
		END `Drum Kit Level`,
		case
			when yesterday.`Transfer Kit Level` - today.`Transfer Kit Level` >= 1 
            and today.`Transfer Kit Level` <= {level_threshold} - 1
            or yesterday.`Transfer Kit Level` = 0
            then today.`Transfer Kit Level`
			else 'N/A'
		END `Transfer Kit Level`,
		case
			when yesterday.`Fuser Kit Level` - today.`Fuser Kit Level` >= 1 
            and today.`Fuser Kit Level` <= {level_threshold} - 1
            or yesterday.`Fuser Kit Level` = 0
            then today.`Fuser Kit Level`
			else 'N/A'
		END `Fuser Kit Level`,
		case
			when yesterday.`Cleaning Kit Level` - today.`Cleaning Kit Level` >= 1 
            and today.`Cleaning Kit Level` <= {level_threshold} - 1
            or yesterday.`Cleaning Kit Level` = 0
            then today.`Cleaning Kit Level`
			else 'N/A'
		END `Cleaning Kit Level`,
		case
			when yesterday.`Maintenance Combo Kit Level` - today.`Maintenance Combo Kit Level` >= 1 
            and today.`Maintenance Combo Kit Level` <= {level_threshold} - 1
            or yesterday.`Maintenance Combo Kit Level` = 0
            then today.`Maintenance Combo Kit Level`
			else 'N/A'
		END `Maintenance Combo Kit Level`,
		case
			when yesterday.`Document Feeder Kit Level` - today.`Document Feeder Kit Level` >= 1 
            and today.`Document Feeder Kit Level` <= {level_threshold} - 1
            or yesterday.`Document Feeder Kit Level` = 0
            then today.`Document Feeder Kit Level`
			else 'N/A'
		END `Document Feeder Kit Level`,
		case
			when yesterday.`Roller Level` - today.`Roller Level` >= 1 
            and today.`Roller Level` <= {level_threshold} - 1
            or yesterday.`Roller Level` = 0
            then today.`Roller Level`
			else 'N/A'
		END `Roller Level`
	from
		(
		select
			DATE(substr(`Report Content DateTime`, 7, 4) || '-' || substr(`Report Content DateTime`, 1, 2) || '-' || substr(`Report Content DateTime`, 4, 2) ) datetime, *
		from
			consumable_levels
		where
			datetime = Date('NOW', '-1 day')) yesterday, (
		select
			DATE(substr(`Report Content DateTime`, 7, 4) || '-' || substr(`Report Content DateTime`, 1, 2) || '-' || substr(`Report Content DateTime`, 4, 2) ) datetime, *
		from
			consumable_levels
		where
			datetime = Date('NOW')) today
	where
		yesterday.`Serial Number` = today.`Serial Number` )


# 用已知的 goods_type 去填補 past_delivery_data 中 goods_type 為 NULL 的欄位
update
	past_delivery_data
set
	goods_type = (
	select
		goods_type
	from
		(
		select
			goods_type, goods_name
		from
			past_delivery_data
		where
			goods_type is not null
		group by
			goods_name)
	where
		goods_name = past_delivery_data.goods_name )
where
	goods_type is null

# 尋找某個序號的最後配送時間及配送的產品
select
	serial,
	Date(substr(arrive_date , 1, 10)) last_deliver_date,
	goods_name,
	goods_type
from
	past_delivery_data
where
	serial = 'AABBCC'
order by
	last_deliver_date
desc
limit 1

# 將過去有的資訊剔除，只找出 past_delivery 中新出現的資料，之後需要 insert or replace 至 deliver_status 中，且將 need_refill 設為 -1
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

# 刪除 VIEW
DROP VIEW IF EXISTS two_days_level_diff;

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

# 若不存在此序號機器，新增至 deliver_status
INSERT OR IGNORE INTO deliver_status 
SELECT
	c."Serial Number" AS serial_number,
	'黑' AS 'goods_type',
	0 need_refill,
	0 need_refill_count
FROM
	consumable_levels as c
WHERE "Black Level" != 'N/A'

# 更新所有的應該追蹤的產品的用量
REPLACE INTO product_level 
SELECT
	DATE('NOW') AS last_update_date,
	c."Serial Number" AS serial_number,
	'黑' AS 'goods_type',
	CASE WHEN "Black Level" >= 0 THEN "Black Level" ELSE 'N/A' END product_level
FROM
	consumable_levels as c
WHERE "Black Level" != 'N/A'

# 依據目前用量以及先前的寄送狀態判斷此次是否需要寄送
