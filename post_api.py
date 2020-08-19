#!/usr/local/bin/python3

import requests
import psutil
import json
import os
from datetime import date

api_url = "https://jsonplaceholder.typicode.com/todos/1" #http://foo.bar/test.php"
dir_path = "/etc"

now = date.today()
formated_date = now.strftime("%d-%m-%Y")

disk_total = psutil.disk_usage('/')
disk_free = disk_total.free #bytes

files_count = sum(len(files) for root, dirs, files in os.walk(dir_path))

message = { "current_date": formated_date, "api_version": "v1", "tdisk": disk_free, "tfiles": files_count }

resp = requests.post(api_url, json=message)
response = resp.json()

with open('/tmp/response.json', 'a') as file:
   json.dump(response, file)
