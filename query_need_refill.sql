select
	DISTINCT consumable_levels.`Product Model Name` '機型',
	deliver_status.serial_number '序號',
	consumable_levels.`Asset Number` '資產編號',
	deliver_status.goods_name '品項',
	deliver_status.goods_type '品名',
	consumable_levels.`Site` '所在地',
	consumable_levels.`Region` '地區',
	consumable_levels.`Customer Name` '客戶',
	consumable_levels.`Building` '所屬大樓',
	consumable_levels.`Level` '樓層',
	consumable_levels.`Usage Count Date` '最後用量資訊收集時間'
from
	deliver_status
join consumable_levels
where
	deliver_status.need_refill = 1
	and deliver_status.serial_number = consumable_levels.`Serial Number`