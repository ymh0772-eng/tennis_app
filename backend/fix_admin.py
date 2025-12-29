import sys
import os

# Add current directory to sys.path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
from models import Member

def fix_admin():
    db = SessionLocal()
    target_phone = "01047331067" # 관리자(총무) 번호
    
    try:
        member = db.query(Member).filter(Member.phone == target_phone).first()

        if member:
            member.is_approved = True
            member.role = "ADMIN"
            db.commit()
            print(f"✅ [성공] {member.name}({member.phone})님을 승인하고 ADMIN 권한을 부여했습니다.")
        else:
            print(f"❌ [실패] 전화번호 {target_phone} 회원을 찾을 수 없습니다. (회원가입은 되어 있나요?)")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    fix_admin()
