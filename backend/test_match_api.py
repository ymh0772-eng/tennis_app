import json
import urllib.request
import urllib.error
import random
import string
import time

BASE_URL = "http://localhost:8000"

def post_json(url, data):
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode('utf-8'),
        headers={'Content-Type': 'application/json'}
    )
    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode())
    except urllib.error.HTTPError as e:
        print(f"HTTP Error {e.code}: {e.read().decode()}")
        return None
    except Exception as e:
        print(f"Error: {e}")
        return None

def create_random_member():
    phone = "".join(random.choices(string.digits, k=11))
    data = {
        "name": f"TestUser_{phone[-4:]}",
        "phone": phone,
        "birth": "2000",
        "pin": "1234"
    }
    return post_json(f"{BASE_URL}/members/", data)

def test_create_match():
    # Wait a bit for server to start if just launched
    time.sleep(2)
    
    print("Creating 4 members...")
    m1 = create_random_member()
    m2 = create_random_member()
    m3 = create_random_member()
    m4 = create_random_member()
    
    if not all([m1, m2, m3, m4]):
        print("Failed to create members for match test. Ensure server is running.")
        return

    print(f"Members: {m1['id']}, {m2['id']}, {m3['id']}, {m4['id']}")
    
    match_data = {
        "team_a_player1_id": m1['id'],
        "team_a_player2_id": m2['id'],
        "team_b_player1_id": m3['id'],
        "team_b_player2_id": m4['id'],
        "score_team_a": 6,
        "score_team_b": 4
    }
    
    print("Sending match data:", match_data)
    result = post_json(f"{BASE_URL}/matches", match_data)
    
    if result:
        print("✅ Match created successfully!")
        print("Response:", result)
    else:
        print("❌ Failed to create match")

if __name__ == "__main__":
    test_create_match()
