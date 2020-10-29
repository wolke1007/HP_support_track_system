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
        'DB_NAME'
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
    combined_sheet.save(combined_sheet_name + ".xlsx")

def set_deliver_status():
    #TODO not implement yet
    pass

if __name__ == '__main__':
    config = load_config()
    validate_config(config)
    PAST_DELIVERY_DATA_PATH = config.get('DIRECTORY_PATH').get('past_delivery_data')
    CONSUMABLE_LEVELS_DATA_PATH = config.get('DIRECTORY_PATH').get('consumable_levels_data')
    COMBINED_PAST_DELIVERY_SHEET_NAME = config.get('COMBINED_SHEET_NAME').get('past_delivery')
    COMBINED_CONSUMABLE_LEVELS_SHEET_NAME = config.get('COMBINED_SHEET_NAME').get('consumable_levels')
    PAST_DELIVERY_SHEET_FIRST_ROW = config.get('SHEET_FIRST_ROW').get('past_delivery_data')
    CONSUMABLE_LEVELS_SHEET_FIRST_ROW = config.get('SHEET_FIRST_ROW').get('consumable_levels_data')
    DB_NAME = config.get('DB_NAME')

    db_conn = sqlite3.connect(DB_NAME)
    c = db_conn.cursor()

    # 將資料夾內過去 60 天 mail 中已經配送過的資料整理成可匯入 SQLite 的格式
    past_delivery_data_to_excel(PAST_DELIVERY_DATA_PATH, COMBINED_PAST_DELIVERY_SHEET_NAME, PAST_DELIVERY_SHEET_FIRST_ROW)
    excel_file = pd.read_excel(COMBINED_PAST_DELIVERY_SHEET_NAME + ".xlsx",
                                        sheet_name='Sheet',
                                        header=0)
    #將通整好的 excel 匯入至 SQLite 中
    excel_file.to_sql('past_delivery_data', db_conn, if_exists='append', index=False)

    # 將資料夾內客戶閥值資料整理成可匯入 SQLite 的格式
    consumable_levels_data_to_excel(CONSUMABLE_LEVELS_DATA_PATH, COMBINED_CONSUMABLE_LEVELS_SHEET_NAME, CONSUMABLE_LEVELS_SHEET_FIRST_ROW)
    excel_file = pd.read_excel(COMBINED_CONSUMABLE_LEVELS_SHEET_NAME + ".xlsx",
                                        sheet_name='Sheet',
                                        header=0)
    #將通整好的 excel 匯入至 SQLite 中
    excel_file.to_sql('consumable_levels', db_conn, if_exists='append', index=False)

    set_deliver_status()
    
    c.close()
    db_conn.close()