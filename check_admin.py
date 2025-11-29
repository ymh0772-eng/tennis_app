from sqlalchemy.orm import Session
from backend.database import SessionLocal
from backend import models

def check_admin():
    db = SessionLocal()
    admin = db.query(models.Member).filter(models.Member.name == "관리자(총무)").first()
    if admin:
        print(f"Admin Found: Name='{admin.name}', Phone='{admin.phone}', PIN='{admin.pin}'")
    else:
        print("Admin NOT found")
    db.close()

if __name__ == "__main__":
    check_admin()
