import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), 'backend'))

from sqlalchemy.orm import Session
from backend.database import SessionLocal
from backend import models
import re

def fix_admin_user(phone: str):
    db = SessionLocal()
    try:
        # Try to find by clean phone first
        clean_phone = re.sub(r'[^0-9]', '', str(phone))
        user = db.query(models.Member).filter(models.Member.phone == clean_phone).first()
        
        # If not found, try finding by hyphenated phone (assuming standard format)
        if not user:
             hyphenated_phone = f"{clean_phone[:3]}-{clean_phone[3:7]}-{clean_phone[7:]}"
             user = db.query(models.Member).filter(models.Member.phone == hyphenated_phone).first()

        if user:
            print(f"User found: {user.name} ({user.phone})")
            print(f"Current Status - Role: {user.role}, Approved: {user.is_approved}")
            
            # Force update
            user.role = "admin"
            user.is_approved = True
            user.phone = clean_phone # Ensure phone is stored without hyphens to match main.py logic
            
            db.commit()
            db.refresh(user)
            
            print(f"Updated Status - Role: {user.role}, Approved: {user.is_approved}, Phone: {user.phone}")
            print("Successfully forced admin update.")
        else:
            print(f"User with phone number {phone} (or {clean_phone}) not found.")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    TARGET_PHONE = "01047331067"
    fix_admin_user(TARGET_PHONE)
