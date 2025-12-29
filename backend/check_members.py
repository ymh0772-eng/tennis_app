import sys
import os

# Add current directory to sys.path to ensure imports work
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
from models import Member

def check_members():
    db = SessionLocal()
    try:
        members = db.query(Member).all()

        print(f"--- 현재 DB 저장된 회원: 총 {len(members)}명 ---")
        for member in members:
            print(f"[{member.id}] 이름: {member.name} / 권한: {member.role}")
        print("---------------------------------------------")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    check_members()
