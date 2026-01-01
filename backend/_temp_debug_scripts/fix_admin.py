from database import SessionLocal
from models import Member

def approve_admin():
    db = SessionLocal()
    try:
        phone = "01047331067"
        member = db.query(Member).filter(Member.phone == phone).first()
        if member:
            member.is_approved = True
            member.role = "ADMIN"
            db.commit()
            print("Success")
        else:
            print("Failure: Member not found")
    except Exception as e:
        print(f"Failure: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    approve_admin()
