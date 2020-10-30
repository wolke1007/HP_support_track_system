# HP_support_track_system

## 目的
整理出需要派送物資之公司與物資對應列表

## 程式流程
1. 建立 DB 所需 table 與 view
2. 將下列兩種資料放進 SQLite DB 中
    * 目前設備用量清單
    * 過去派送紀錄
3. 修復缺失資料(例如商品名稱有，但是品項為空)
4. 判斷寄送規則
5. 輸出表單

## 使用流程
1. 手動建立兩資料夾:
   * PastDeliveryData
   * ConsumableLevelsData
2. 將對應檔案放進對應資料夾
   * PastDeliveryData <-- 放過去的派送資料 excel 檔(目前支援 xslx 格式)
   * ConsumableLevelsData <-- 放耗材用量採集資料 excel 檔(目前支援 xslx 格式)
3. 執行程式
4. 選擇選單功能:
   1. 匯入目前設備用量清單  
      > 將資料夾內所有 excel 表格匯入至資料庫中
   2. 匯入過去派送紀錄  
      > 將資料夾內所有 excel 表格匯入至資料庫中
   3. 取得應派送設備表單  
      > 依當前資料庫中內容做判斷看哪一些機器需要派送耗材並匯出成 csv 檔案
   4. 套用新設定(閥值)
      > 若 config 檔中的閥值有調整時需要選此選項讓 DB 內判斷一起更改
   5. 創建全新 DB
      > 刪除原本 DB 並創建全新 DB

##### 技術部分參考以下網頁內容：
* https://www.runoob.com/sqlite/sqlite-tutorial.html
* https://towardsdatascience.com/turn-your-excel-workbook-into-a-sqlite-database-bc6d4fd206aa