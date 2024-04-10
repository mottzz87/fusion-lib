# 中银香港 余量预约查询
# eg:
# python3 zhongyin-order.py
# python3 zhongyin-order.py -date 19/04/2024 
# python3 zhongyin-order.py -district 中西區
# python3 zhongyin-order.py -date 19/04/2024 -time 09:00

def install_module(module):
    try:
        subprocess.check_call(["pip3", "install", module])
    except subprocess.CalledProcessError:
        print(f"Failed to install {module}")

# 检查并安装所需的模块
try:
    import subprocess
except ImportError:
    print("subprocess module is not installed. Installing...")
    install_module("subprocess")

try:
    import requests
except ImportError:
    print("requests module is not installed. Installing...")
    install_module("requests")
    
try:
    import argparse
except ImportError:
    print("argparse module is not installed. Installing...")
    install_module("argparse")

# 导入已安装的模块
import subprocess
import argparse
import requests
from datetime import datetime, timedelta
import argparse
import requests

# 定义请求参数
url = "https://transaction.bochk.com/whk/form/openAccount/jsonAvailableBrsByDT.action"
headers = {
    "Cookie": "xxxxxxxxxxxx"
}

a = [
    {"label": "09:00", "value": "P01"},
    {"label": "09:45", "value": "P02"},
    {"label": "10:30", "value": "P03"},
    {"label": "11:15", "value": "P04"},
    {"label": "14:00", "value": "P05"},
    {"label": "14:45", "value": "P06"},
    {"label": "15:30", "value": "P07"},
    {"label": "16:15", "value": "P08"}
]

b = [
    {"label": "中西區", "value": "_central_western_district"},
    {"label": "東區", "value": "_eastern_district"},
    {"label": "離島區", "value": "_island_district"},
    {"label": "九龍城區", "value": "_kowloon_city_district"},
    {"label": "葵青區", "value": "_kwai_tsing_district"},
    {"label": "觀塘區", "value": "_kwun_tong_district"},
    {"label": "北區", "value": "_north_district"},
    {"label": "西貢區", "value": "_sai_kung_district"},
    {"label": "沙田區", "value": "_sha_tin_district"},
    {"label": "深水埗區", "value": "_sham_shui_po_district"},
    {"label": "南區", "value": "_southern_district"},
    {"label": "大埔區", "value": "_tai_po_district"},
    {"label": "荃灣區", "value": "_tsuen_wan_district"},
    {"label": "屯門區", "value": "_tuen_mun_district"},
    {"label": "灣仔區", "value": "_wan_chai_district"},
    {"label": "黃大仙區", "value": "_wong_tai_sin_district"},
    {"label": "油尖旺區", "value": "_yau_tsim_mong_district"},
    {"label": "元朗區", "value": "_yuen_long_district"}
]

# 定义函数进行请求
def make_request(date, time, district):
    data = {
        "bean.appDate": date,
        "bean.appTime": time,
        "bean.district": district,
        "bean.precondition": "D"
    }
    response = requests.post(url, headers=headers, data=data)
    return response.json()

# 解析命令行参数
parser = argparse.ArgumentParser(description="Script to query API with dynamic parameters")
parser.add_argument("-date", help="Date for querying (format: dd/mm/yyyy)")
parser.add_argument("-time", help="Time for querying", choices=[item["label"] for item in a])
parser.add_argument("-district", help="District for querying", choices=[item["label"] for item in b])
args = parser.parse_args()

# 计算日期范围，推迟6-7天并排除周日
today = datetime.now()
start_date = today + timedelta(days=5)
end_date = today + timedelta(days=8)

# 计算符合要求的日期范围
dates = []
for i in range((end_date - start_date).days + 1):
    next_day = start_date + timedelta(days=i)
    if next_day.weekday() != 6:  # 排除周日
        dates.append(next_day.strftime("%d/%m/%Y"))

# 如果参数提供了特定日期，仅使用提供的日期
if args.date:
    dates = [args.date]

# 执行请求并输出结果
for date in dates:
    for district_item in b:
        district_label = district_item["label"]
        district_value = district_item["value"]

        for time_item in a:
            time_label = time_item["label"]
            time_value = time_item["value"]
            
            if args.time and time_label != args.time:
                continue
            if args.district and district_label != args.district:
                continue
            
            response = make_request(date, time_value, district_value)
            print(f"Date: {date}, District: {district_label}, Time: {time_label}")
            if len(response) > 1:
                response.pop(0)
                for item in response:
                    print(item["messageCn"])               

