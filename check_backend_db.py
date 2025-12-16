
import sqlite3
import os

# Explicitly target the backend DB
db_path = os.path.join(os.getcwd(), 'backend', 'tennis_club.db')
print(f"Checking DB at: {db_path}")

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

print("--- MEMBERS in BACKEND DB ---")
try:
    cursor.execute("SELECT name, phone, is_approved FROM members")
    rows = cursor.fetchall()
    for row in rows:
        print(f"Name: {row[0]}, Phone: {row[1]}, Approved: {row[2]}")
except Exception as e:
    print(f"Error reading DB: {e}")

conn.close()
