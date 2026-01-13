from database import SessionLocal
from models import Member
import re

def sanitize_phone(phone: str) -> str:
    if not phone:
        return ""
    return re.sub(r'[^0-9]', '', str(phone))

def grant_admin():
    db = SessionLocal()
    phone = "01047331067" # Admin phone number from screenshot
    clean_phone = sanitize_phone(phone)
    
    try:
        member = db.query(Member).filter(Member.phone == clean_phone).first()
        if member:
            member.role = "ADMIN"
            member.is_approved = True
            db.commit()
            print(f"✅ Success: User {member.name} ({member.phone}) is now ADMIN and APPROVED.")
        else:
            print(f"❌ Error: User with phone {clean_phone} not found.")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    grant_admin()
