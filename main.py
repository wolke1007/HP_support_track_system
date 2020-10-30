# coding=UTF-8

import yaml
from datetime import datetime
import csv
import subprocess
import os
import openpyxl
from zipfile import BadZipfile
import pandas as pd
import sqlite3
import time


def load_config():
    """
    讀取 config.yaml
    """
    try:
        with open('config.yaml', 'r', encoding='utf-8') as stream:
            config = yaml.safe_load(stream)
    except FileNotFoundError:
        input("[ERROR] config.yaml not found!\n"
              "press Enter key to close this window...")
        exit(1)
    return config

def validate_config(config):
    """
    檢查 config.yaml 各主要 key 是否健全沒缺失
    """
    keys_should_be_exist = [
        'DIRECTORY_PATH',
        'COMBINED_SHEET_NAME',
        'SHEET_FIRST_ROW',
        'DB_NAME',
        'SQL_COMMANDS'
    ]
    for key in keys_should_be_exist:
        if key not in config.keys():
            print('[ERROR] main key missing! please check key: {key} is exist in config.yaml'.format(
                key=key))
            input("press Enter key to close this window...")
            exit(1)

def past_delivery_data_to_excel(directory_path:str, combined_sheet_name:str, sheet_first_row:list):
    """
    將資料夾內過去 60 天 mail 中已經配送過的資料整理成可匯入 SQLite 的格式
    """
    first_row = None
    combined_sheet = openpyxl.Workbook()
    combined_sheet.create_sheet()
    if(not os.path.isdir(directory_path)):
        input("[ERROR] directory {} not found!\n"
              "press Enter key to close this window...".format(directory_path))
        exit(1)
    combined_sheet.active.append((cell for cell in sheet_first_row))
    for file_name in os.listdir(directory_path):
        if(file_name == ".DS_Store"):
            continue  # 跳過這種自動產生的檔案
        if("imported_" in file_name):
            continue  # 跳過已經匯入過的檔案
        try:
            read_file = openpyxl.load_workbook(os.path.join(directory_path, file_name))
        except BadZipfile:
            input("[ERROR] file {file_name} still open, close it first!\n"
              "press Enter key to close this window...".format(file_name=file_name))
            exit(1)
        sheet = read_file.active
        row_cnt = 0
        for row in sheet.rows:
            if(row[0].value == None):  # 如果該行為空則略過
                row_cnt+=1
                continue
            elif(row[0].value == "序号"):  # 如果判斷為第一列的title則要看是否已經有了就不在加入
                row_cnt+=1
                continue
            else:
                combined_sheet.active.append((cell.value for cell in row))
        # 此檔案匯入結束，於檔名前面加入 prefix
        os.rename(os.path.join(directory_path, file_name), os.path.join(directory_path, "imported_"+file_name))
    combined_sheet.save(combined_sheet_name + ".xlsx")

def consumable_levels_data_to_excel(directory_path:str, combined_sheet_name:str, sheet_first_row:list):
    """
    將資料夾內客戶閥值資料整理成可匯入 SQLite 的格式
    每個檔案需先取出第二列的時間，並新增一叫做 content_date 的 column 並全填上剛取到的時間
    然後刪除第一與第二列
    """
    combined_sheet = openpyxl.Workbook()
    combined_sheet.create_sheet()
    if(not os.path.isdir(directory_path)):
        input("[ERROR] directory {} not found!\n"
              "press Enter key to close this window...".format(directory_path))
        exit(1)
    
    combined_sheet.active.append((cell for cell in sheet_first_row))
    for file_name in os.listdir(directory_path):
        if(file_name == ".DS_Store"):
            continue  # 跳過這種自動產生的檔案
        if("imported_" in file_name):
            continue  # 跳過已經匯入過的檔案
        try:
            read_file = openpyxl.load_workbook(os.path.join(directory_path, file_name))
        except BadZipfile:
            input("[ERROR] file {file_name} still open, close it first!\n"
              "press Enter key to close this window...".format(file_name=file_name))
            exit(1)
        sheet = read_file.active
        row_cnt = 0
        report_content_date = 0
        for row in sheet.rows:
            if(row[0].value == None or row_cnt == 0 or row_cnt == 2):  
                # 如果該行為空略過
                # 第一列是產 report 的時間，不需要故略過
                # 第三列是 column header，不需要故略過
                row_cnt+=1
            elif(row_cnt == 1):  # 第二列需要取時間
                row_cnt+=1
                report_content_date = row[1].value
            else:
                row_cnt+=1
                combined_sheet.active.append((report_content_date,) + (tuple)(cell.value for cell in row))
        # 此檔案匯入結束，於檔名前面加入 prefix
        os.rename(os.path.join(directory_path, file_name), os.path.join(directory_path, "imported_"+file_name))
    combined_sheet.save(combined_sheet_name + ".xlsx")

def set_deliver_status(db_conn):
    """
    檢查昨天與今天的墨水或耗材用量是否有減少
    如果有減少，或是低於閥值則列出
    並去檢查是否需要配送，若未配送過則設為 TRUE
    """
    goods_type_dict = {
        2: "黑",
        3: "藍",
        4: "紅",
        5: "藍鼓",
        6: "黃鼓",
        7: "紅鼓",
        8: "黑鼓",
        9: "drum kit",
        10: "transfer kit",
        11: "fuser kit",
        12: "clean kit",
        13: "maintainace combo kit",
        14: "document feeder kit",
        15: "roller"
    }
    cur = db_conn.cursor()
    for row in cur.execute(SQL_COMMANDS.get('level_diff')):
        # update deliver_status if need
        cur2 = db_conn.cursor()
        print(row)
        check_need_refill = SQL_COMMANDS.get('check_need_refill').format(serial_number=row[0])
        result = cur2.execute(check_need_refill).fetchone()
        if (result is None):
            print("此序號 {serial} 機器尚未有派送資料".format(serial=row[0]))
            # 在 deliver_status 新增一欄，但只填上序號與品項(查 goods_type 的表)
            index = 0
            cur3 = db_conn.cursor()
            for query_item in row:
                if type(query_item) is int:  # 這邊姑且使用數字來判斷是否有值，其他的序號、日期、N/A 皆為文字
                    goods_type = goods_type_dict.get(index)
                    insert_deliver_status = SQL_COMMANDS.get('insert_deliver_status').format(serial_number=row[0], goods_type=goods_type)
                    print(insert_deliver_status)
                    print("insert deliver_status")
                    cur3.execute(insert_deliver_status)
                index+=1
            db_conn.commit()
            cur3.close()
        else:
            print("此序號 {serial} 機器已有派送資料".format(serial=row[0]))
            print(result)
            if (result[0] == True):
                print("當前 need_refill 已經是 True，不進行動作")
            if (result[0] == False):
                print("當前 need_refill 為 False，將設為 True")
                index = 0
                cur3 = db_conn.cursor()
                for query_item in row:
                    if type(query_item) is int:  # 這邊姑且使用數字來判斷是否有值，其他的序號、日期、N/A 皆為文字
                        goods_type = goods_type_dict.get(index)
                        update_deliver_status = SQL_COMMANDS.get('update_deliver_status').format(serial_number=row[0], goods_type=goods_type)
                        print(update_deliver_status)
                        print("update deliver_status")
                        cur3.execute(update_deliver_status)
                    index+=1
                db_conn.commit()
                cur3.close()
        cur2.close()
    cur.close()

if __name__ == '__main__':
    config = load_config()
    validate_config(config)
    LEVEL_THRESHOLD = config.get('LEVEL_THRESHOLD')
    PAST_DELIVERY_DATA_PATH = config.get('DIRECTORY_PATH').get('past_delivery_data')
    CONSUMABLE_LEVELS_DATA_PATH = config.get('DIRECTORY_PATH').get('consumable_levels_data')
    COMBINED_PAST_DELIVERY_SHEET_NAME = config.get('COMBINED_SHEET_NAME').get('past_delivery')
    COMBINED_CONSUMABLE_LEVELS_SHEET_NAME = config.get('COMBINED_SHEET_NAME').get('consumable_levels')
    PAST_DELIVERY_SHEET_FIRST_ROW = config.get('SHEET_FIRST_ROW').get('past_delivery_data')
    CONSUMABLE_LEVELS_SHEET_FIRST_ROW = config.get('SHEET_FIRST_ROW').get('consumable_levels_data')
    DB_NAME = config.get('DB_NAME')
    SQL_COMMANDS = config.get('SQL_COMMANDS')

    def apply_settings(arg):
        print("1")
    
    def import_past_deliver(db_conn):
        print("beging import past devier data...")
        # 將資料夾內過去 60 天 mail 中已經配送過的資料整理成可匯入 SQLite 的格式
        past_delivery_data_to_excel(PAST_DELIVERY_DATA_PATH, COMBINED_PAST_DELIVERY_SHEET_NAME, PAST_DELIVERY_SHEET_FIRST_ROW)
        excel_file = pd.read_excel(COMBINED_PAST_DELIVERY_SHEET_NAME + ".xlsx",
                                            sheet_name='Sheet',
                                            header=0)
        #將通整好的 excel 匯入至 SQLite 中
        excel_file.to_sql('past_delivery_data', db_conn, if_exists='append', index=False)
        # 用已知的 goods_type 去填補 past_delivery_data 中 goods_type 為 NULL 的欄位
        cur = db_conn.cursor()
        sql_command = SQL_COMMANDS.get('fill_known_goods_type')
        cur.execute(sql_command)
        cur.close()
        print("end of import past devier data...")
    
    def import_consumable_levels(db_conn):
        print("beging import consumable levels data...")
        # 將資料夾內客戶閥值資料整理成可匯入 SQLite 的格式
        consumable_levels_data_to_excel(CONSUMABLE_LEVELS_DATA_PATH, COMBINED_CONSUMABLE_LEVELS_SHEET_NAME, CONSUMABLE_LEVELS_SHEET_FIRST_ROW)
        excel_file = pd.read_excel(COMBINED_CONSUMABLE_LEVELS_SHEET_NAME + ".xlsx",
                                            sheet_name='Sheet',
                                            header=0)
        #將通整好的 excel 匯入至 SQLite 中
        excel_file.to_sql('consumable_levels', db_conn, if_exists='append', index=False)
        print("end of  import consumable levels data...")
    
    def get_deliver_status(db_conn):
        print("4")
        set_deliver_status(db_conn)
    
    def reset_db(arg):
        print("beging db reset...")
        os.remove(DB_NAME)
        f = open(DB_NAME, "a")
        f.close()
        new_db_conn = sqlite3.connect(DB_NAME)
        cur = new_db_conn.cursor()
        create_db_commands = SQL_COMMANDS.get('reset_db_commands')
        for key in create_db_commands.keys():
            sql_command = create_db_commands.get(key)
            if (key == "create_view_level_diff"):
                sql_command = create_db_commands.get(key).format(level_threshold=str(LEVEL_THRESHOLD))
            cur.execute(sql_command)
            time.sleep(1)
        cur.close()
        print("end of db reset...")

    function_list = {
        "1": apply_settings,
        "2": import_past_deliver,
        "3": import_consumable_levels,
        "4": get_deliver_status,
        "5": reset_db  # delete all tables and views
    }

    while True:
        choose = input("請輸入功能代號:\n"
        "1. 套用新設定(閥值)\n"
        "2. 匯入過去派送紀錄\n"
        "3. 匯入目前設備用量清單\n"
        "4. 取得應派送設備表單\n"
        "5. 重設 DB 設定(!注意!資料將被清空)\n"
        "6. 退出程式\n")
        if choose == "6":
            print("exit program.")
            break
        db_conn = sqlite3.connect(DB_NAME)
        func = function_list.get(choose, lambda: print("Invalid number!\n\n"))
        func(db_conn)  # 執行選取的邏輯
        db_conn.close()
        