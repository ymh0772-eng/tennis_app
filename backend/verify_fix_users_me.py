from fastapi.testclient import TestClient
from main import app, create_access_token
import sys

def verify_users_me():
    try:
        from fastapi.testclient import TestClient
    except ImportError:
        print("TestClient not available (missing httpx?). Skipping.")
        return

    client = TestClient(app)
    
    # 1. Create a token for a known user (Admin: 01047331067)
    # We do NOT need to hit /login, we can just mint a token directly for testing.
    token = create_access_token(data={"sub": "01047331067"})
    
    headers = {"Authorization": f"Bearer {token}"}
    
    print("Testing GET /users/me ...")
    response = client.get("/users/me", headers=headers)
    
    if response.status_code == 200:
        data = response.json()
        print("Success! /users/me returned 200 OK")
        print(f"User: {data.get('name')} ({data.get('phone')})")
        print(f"Role: {data.get('role')}")
    else:
        print(f"Failure! Status Code: {response.status_code}")
        print(f"Response: {response.text}")

if __name__ == "__main__":
    verify_users_me()
