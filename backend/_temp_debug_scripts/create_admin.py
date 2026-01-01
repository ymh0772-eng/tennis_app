import sys
import os

# Add current directory to sys.path to ensure imports work if run from backend dir
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal, engine
import models
import re

# Ensure tables exist
models.Base.metadata.create_all(bind=engine)

def sanitize_phone(phone: str) -> str:
    if not phone:
        return ""
    return re.sub(r'[^0-9]', '', str(phone))

def create_admin():
    db = SessionLocal()
    try:
        phone = "01047331067"
        clean_phone = sanitize_phone(phone)
        
        # Check if exists
        existing = db.query(models.Member).filter(models.Member.phone == clean_phone).first()
        if existing:
            print(f"User with phone {clean_phone} already exists.")
            # Update to admin
            existing.name = "관리자(총무)"
            existing.pin = "9703"
            existing.birth = "1970"
            existing.role = "ADMIN"
            existing.is_approved = True
            print("Updated existing user to Admin.")
        else:
            admin_user = models.Member(
                phone=clean_phone,
                pin="9703",
                name="관리자(총무)",
                birth="1970",
                role="ADMIN",
                is_approved=True
            )
            db.add(admin_user)
            print("Created new Admin user.")
        
        db.commit()
        print("관리자 계정 생성 완료")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    create_admin()
