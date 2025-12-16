
import sys
import os

# Set up path to import from backend
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from backend.database import SessionLocal
from backend import models

db = SessionLocal()
print("--- RESET ALL (EXCEPT ADMIN) ---")

# 1. 대상: 관리자(01047331067)가 아닌 모든 회원
target_users = db.query(models.Member).filter(models.Member.phone != '01047331067').all()

count = 0
for user in target_users:
    user.is_approved = False
    print(f"RESET: {user.name} ({user.phone}) -> Unapproved")
    count += 1

db.commit()
db.close()
print(f"--- COMPLETE: {count} users reset ---")
