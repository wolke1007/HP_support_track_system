# HP_support_track_system

## 目的
### 為解決其商業目的
1. 商業目的為幫客戶端殘餘用量低於閥值的設備派送替換資源過去(或派人去換)
2. 為了達到其商業目的需有以下數據:
    * 目前低於閥值的設備
    * 曾經派送過的紀錄
    * 整理出既低於閥值且未派送給客戶的設備
3. 而目前已經有的數據則是:
    * 所有設備當前用量的數據
    * 過去的派送紀錄

### 程式目的
因此此程式目的則是透過第三點的所有數據整理成第二點

## 程式流程
1. 建立 DB 所需 table 與 view
2. 將下列兩種資料從 EXCEL 中讀出並匯入 SQLite DB
    * 目前設備用量清單
    * 過去派送紀錄
3. 修復缺失資料(例如商品名稱有，但是品項為空)
4. 判斷寄送規則更新是否要寄送
5. 更新設備的數據
6. 輸出待寄送設備的表單

## 使用流程
1. 手動建立兩資料夾:
   * PastDeliveryData
   * ConsumableLevelsData
2. 將對應檔案放進對應資料夾
   * PastDeliveryData <-- 放過去的派送資料 excel 檔(目前支援 xslx 格式)
   * ConsumableLevelsData <-- 放耗材用量採集資料 excel 檔(目前支援 xslx 格式)
3. 執行程式
4. 選擇選單功能:  
   * 第一次執行更新並取得應派送設備表單  
      > 與下一項選項 "更新並取得應派送設備表單" 執行內容相同  
        差別在此選項篩選出的設備會排除掉已經派送過的避免重複派送  
   * 更新並取得應派送設備表單  
      > 將資料夾內所有 excel 表格匯入至資料庫中  
        依當前資料庫中內容做判斷看哪一些設備需要派送耗材  
        於此程式資料夾中匯出成 csv 檔案  
   * 套用新設定(閥值)，需要再使用功能 1 才能產出根據新閥值計算的設備表單
      > 在 config.yaml 中更改 LEVEL_THRESHOLD 後需要執行這個選項程式才會吃到新設定  
   * 刪除AND創建全新DB
      > 刪除原本 DB 並創建全新 DB
   * 關閉程式

## 備註
1. 防毒軟體會擋因為有建立檔案(db file)跟更改檔案(db file and excel rename)的動作，可能需要開權限
2. 使用 pyinstall 打包，需要用 pyinstaller main.spec --onefile 指令，因為 pandas bug 的關係
3. 目前匯入的檔案格式支援 xlsx，尚未支援其他格式

##### 技術部分參考以下網頁內容：
* https://www.runoob.com/sqlite/sqlite-tutorial.html
* https://towardsdatascience.com/turn-your-excel-workbook-into-a-sqlite-database-bc6d4fd206aa
