# HP_support_track_system

## 目的
整理出需要派送物資之公司與物資對應列表

## 程式流程
1. 建立 DB 所需 table 與 view
2. 將下列兩種資料放進 SQLite DB 中
    * 目前設備用量清單
    * 過去派送紀錄
3. 修復缺失資料(例如商品名稱有，但是品項為空)
4. 判斷寄送規則
5. 輸出表單

##### 技術部分參考以下網頁內容：
* https://www.runoob.com/sqlite/sqlite-tutorial.html
* https://towardsdatascience.com/turn-your-excel-workbook-into-a-sqlite-database-bc6d4fd206aa