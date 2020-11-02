SELECT DISTINCT
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
    c.`Usage Count Date` AS '最後用量資訊收集時間',
FROM consumable_levels AS c
JOIN deliver_status AS d ON d.serial_number = c.`Serial Number`
WHERE d.need_refill = 1 AND d.need_refill_count = 0
GROUP BY d.serial_number, d.goods_type;