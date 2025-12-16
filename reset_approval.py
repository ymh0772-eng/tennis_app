import sys
import os

# 현재 디렉토리의 backend 폴더를 sys.path에 추가하여 
# models.py 내부의 'from database import Base'가 동작하도록 함
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from backend.database import SessionLocal
from backend import models

db = SessionLocal()
target_names = ["윤나영", "윤정일"]

print("--- 승인 상태 초기화 시작 ---")
# 1. 대상 회원 찾아서 승인 취소 (is_approved = False)
users = db.query(models.Member).filter(models.Member.name.in_(target_names)).all()

for user in users:
    user.is_approved = False
    print(f"✅ {user.name} ({user.phone}) -> 승인 대기 상태로 변경됨")

if not users:
    print("⚠️ 대상 회원을 찾지 못했습니다. 이름을 확인해주세요.")

db.commit()
db.close()
print("--- DB 수정 완료 ---")
