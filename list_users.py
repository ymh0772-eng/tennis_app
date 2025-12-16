import sys
import os

sys.path.append(os.path.join(os.getcwd(), 'backend'))

from backend.database import SessionLocal
from backend import models

db = SessionLocal()
print("--- ALL MEMBERS ---")
users = db.query(models.Member).all()
for user in users:
    print(f"Name: {user.name}, Phone: {user.phone}, Role: {user.role}, Approved: {user.is_approved}")

db.close()
