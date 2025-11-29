import requests
import json

url = "http://localhost:8000/login"
# Use the phone number of the first user we updated
# Based on previous output: Name: Kang Chul-soo, Phone: 010-8026-3967
payload = {
    "phone": "010-4733-1067",
    "pin": "1234"
}
headers = {
    "Content-Type": "application/json"
}

try:
    response = requests.post(url, json=payload, headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response Body: {response.json()}")
    
    if response.status_code == 200:
        print("Login Successful!")
    else:
        print("Login Failed!")
except Exception as e:
    print(f"Error: {e}")
