# coding=UTF-8

import yaml
from datetime import datetime
import csv
import subprocess
import os
from threading import Thread
from queue import Queue
import openpyxl
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
        'DIRECTORY_PATH'
    ]
    for key in keys_should_be_exist:
        if key not in config.keys():
            print('[ERROR] main key missing! please check key: {key} is exist in config.yaml'.format(
                key=key))
            input("press Enter key to close this window...")
            exit(1)


# def get_server_list_from_config():
#     """
#     從 config.yaml 檔中讀取 SERVER_LIST 的值
#     """
#     print("{csv_file_name} not found... "
#           "ip list source : config.yaml\n".format(csv_file_name=config['CSV_FILE_NAME']))
#     server_list = config['SERVER_LIST']
#     if server_list == None:
#         print("[ERROR] SERVER_LIST in config.yaml is empty please check!")
#         input("press Enter key to close this window...")
#         exit(1)
#     return server_list


# def get_server_list_from_csv():
#     """
#     從 config.yaml 中指定的 csv 檔中取資料
#     資料格式為:
#         192.168.2.126 TYPE_1
#         192.168.2.12 TYPE_2
#     這樣的形式紀錄
#     """
#     print("{csv_file_name} found. "
#           "ip list source : {csv_file_name}\n".format(csv_file_name=config['CSV_FILE_NAME']))
#     try:
#         with open(config['CSV_FILE_NAME'], 'r', encoding='utf-8') as csv_file:
#             reader = csv.reader(csv_file)
#             server_list = []
#             for row in reader:
#                 if len(row) == 0:
#                     continue
#                 server_list.append(
#                     {'IP': row[0].strip(),  # 資料的第 0 個資料是 IP
#                      'TYPE': row[1].strip()})  # 資料的第 1 個資料是 TYPE
#     except FileNotFoundError:
#         print("[BUG] BUG IN get_server_list_from_csv()! should not got here.")
#         input("press Enter key to close this window...")
#         exit(1)
#     if len(server_list) == 0:
#         print("[ERROR] {csv_file_name}'s content is empty please check!".format(
#             csv_file_name=config['CSV_FILE_NAME']))
#         input("press Enter key to close this window...")
#         exit(1)
#     return server_list


# def pingme(thread, queue: Queue):
#     """
#     ping server 主要邏輯
#     """
#     while True:
#         server = queue.get()
#         ip = server.get('IP')
#         ret = subprocess.Popen(
#             ["ping.exe", ip.strip(), "-n", "2"], stdout=subprocess.PIPE).communicate()[0]
#         if b"unreachable" in ret:
#             print('ping fail, ', server.get('IP'), ' is not reachable!')
#         else:
#             print(server.get('IP'), 'is alive')
#             reachable_servers.append(server)
#         queue.task_done()


# def get_reachable_servers(server_list: list):
#     """
#     ping server 多執行緒部分的邏輯
#     """
#     print("=========== Start ping all servers ===========")
#     queue = Queue()
#     for thread in range(NUM_THREADS):
#         new_thread = Thread(target=pingme, args=(thread, queue))
#         new_thread.setDaemon(True)
#         new_thread.start()
#     for server in server_list:
#         queue.put(server)
#     queue.join()
#     print("================= End of ping =================")


# def crwaling(thread, queue: Queue):
#     """
#     爬蟲主要邏輯在 page.get_all_element_from_html() 中實現
#     """
#     while True:
#         server = queue.get()
#         if (server):
#             page = server['page']
#             ip = server['server'].get('IP')
#             print("collecting data from server {ip}... ".format(ip=ip))
#             page.get_all_element_from_html()
#             pages.append(page)
#             queue.task_done()


# def get_pages_content(reachable_servers: list, config, pages: list):
#     """
#     爬蟲多執行緒部分的邏輯
#     """
#     print("=========== Start crawling all pages ===========")
#     queue = Queue()
#     threads = []
#     for thread in range(NUM_THREADS):
#         new_thread = Thread(target=crwaling, args=(thread, queue))
#         new_thread.setDaemon(True)
#         new_thread.start()
#         threads.append(new_thread)
#     for server in reachable_servers:
#         page = Page(config=config, page_type=server.get('TYPE'),
#                     ip=server.get('IP'))
#         queue.put({'server': server,
#                    'page': page,
#                    'pages': pages})
#     queue.join()
#     print("================= End of crawling =================")
def past_delivery_data_to_excel(directory_path:str, combined_sheet_name:str, sheet_first_row:list):
    """
    經由過去的 60 天 mail 內容整理出已經配送過且最新的資料
    例如: 
        A 序號的 AA 商品於 2020/10/28 配送
        A 序號的 AA 商品於 2020/10/29 配送
        A 序號的 BB 商品於 2020/10/28 配送
    則應該要整理成類似:
        A 序號的 AA 商品於 2020/10/29 配送  <- 取最新的
        A 序號的 BB 商品於 2020/10/28 配送  <- 不同的商品需保留
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
        read_file = openpyxl.load_workbook(os.path.join(directory_path, file_name))
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

def excel_to_sqlite(excel):
    """
    將通整好的 excel 匯入至 SQLite 中
    """
    db_conn = sqlite3.connect(DB_NAME)
    c = db_conn.cursor()
    excel.to_sql('past_delivery_data', db_conn, if_exists='append', index=False)

if __name__ == '__main__':
    config = load_config()
    validate_config(config)
    DIRECTORY_PATH = config.get('DIRECTORY_PATH')
    COMBINED_SHEET_NAME = config.get('COMBINED_SHEET_NAME')
    SHEET_FIRST_ROW = config.get('SHEET_FIRST_ROW')
    DB_NAME = config.get('DB_NAME')
    past_delivery_data_to_excel(DIRECTORY_PATH, COMBINED_SHEET_NAME, SHEET_FIRST_ROW)
    excel_file = pd.read_excel(COMBINED_SHEET_NAME + ".xlsx",
                                        sheet_name='Sheet',
                                        header=0)
    excel_to_sqlite(excel_file)