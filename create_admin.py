from sqlalchemy.orm import Session
from backend.database import SessionLocal
from backend import models

def create_admin(phone_number: str):
    db = SessionLocal()
    try:
        user = db.query(models.Member).filter(models.Member.phone == phone_number).first()
        if user:
            print(f"User found: {user.name} ({user.phone})")
            user.role = "ADMIN"
            user.is_approved = True
            db.commit()
            print(f"Successfully promoted {user.name} to ADMIN and approved them.")
        else:
            print(f"User with phone number {phone_number} not found.")
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    # Target phone number provided by the user
    TARGET_PHONE = "01047331067"
    create_admin(TARGET_PHONE)
