import sys
import os
script_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(script_dir, 'backend'))

from database import SessionLocal
import models

db = SessionLocal()
targets = ["윤나영", "윤정일"]

print("--- 현재 사용자 목록 ---")
users = db.query(models.Member).all()
for u in users:
    print(f"Name: {u.name}, Phone: {u.phone}, Approved: {u.is_approved}")

print("--- 상태 변경 시작 ---")
for name in targets:
    member = db.query(models.Member).filter(models.Member.name == name).first()
    if member:
        member.is_approved = False
        print(f"✅ {name}님을 '승인 대기' 상태로 변경했습니다.")
    else:
        print(f"⚠️ {name}님을 찾을 수 없어 새로 생성합니다.")
        new_member = models.Member(
            name=name,
            phone=f"0100000000{targets.index(name)}", # Dummy phone
            birth="1990",
            pin="1234",
            is_approved=False,
            role="member"
        )
        db.add(new_member)
        print(f"✅ {name}님을 '승인 대기' 상태로 생성했습니다.")

db.commit()
db.close()
print("--- 완료 ---")
