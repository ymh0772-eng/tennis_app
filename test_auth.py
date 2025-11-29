import requests
import json

BASE_URL = "http://localhost:8000"

def test_auth():
    # 1. Register a new user
    print("Testing Registration...")
    register_data = {
        "name": "Test User",
        "phone": "010-0000-0000",
        "birth": "1980",
        "pin": "1234"
    }
    try:
        response = requests.post(f"{BASE_URL}/members/", json=register_data)
        if response.status_code == 200:
            print("Registration Success:", response.json())
        else:
            print("Registration Failed:", response.text)
    except Exception as e:
        print("Registration Error:", e)

    # 2. Approve the user (simulate admin)
    # We need to manually approve in DB or just assume we can login if we hack it?
    # Wait, the login requires approval.
    # Let's manually approve via python script or just update the DB directly.
    # For this test script, let's just try to login and expect failure (403).
    
    print("\nTesting Login (Unapproved)...")
    login_data = {
        "phone": "010-0000-0000",
        "pin": "1234"
    }
    response = requests.post(f"{BASE_URL}/login", json=login_data)
    if response.status_code == 403:
        print("Login correctly failed (Unapproved).")
    elif response.status_code == 200:
        print("Login Unexpectedly Succeeded!")
    else:
        print(f"Login Failed with {response.status_code}: {response.text}")

    # 3. Approve user
    from sqlalchemy import create_engine, text
    engine = create_engine("sqlite:///tennis_club.db")
    with engine.begin() as conn:
        conn.execute(text("UPDATE members SET is_approved = 1 WHERE phone = '010-0000-0000'"))
    print("\nUser manually approved.")

    # 4. Login again
    print("\nTesting Login (Approved)...")
    response = requests.post(f"{BASE_URL}/login", json=login_data)
    if response.status_code == 200:
        print("Login Success:", response.json())
    else:
        print(f"Login Failed with {response.status_code}: {response.text}")

if __name__ == "__main__":
    test_auth()
