from database import SessionLocal
from models import Member

def check_members():
    db = SessionLocal()
    try:
        members = db.query(Member).all()

        print("--- [Current Member List] ---")
        for m in members:
            print(f"ID: {m.id} | Name: {m.name} | Phone: {m.phone} | Approved: {m.is_approved} | Role: {m.role}")
        print("-----------------------------")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    check_members()
