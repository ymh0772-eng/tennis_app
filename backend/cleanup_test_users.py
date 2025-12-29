import sys
import os

# Add current directory to sys.path to ensure imports work
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from database import SessionLocal
from models import Member, Match
from sqlalchemy import or_

def cleanup_test_users():
    db = SessionLocal()
    try:
        # 1. TestUser 찾기
        print("Searching for users starting with 'TestUser'...")
        test_users = db.query(Member).filter(Member.name.like("TestUser%")).all()
        test_user_ids = [u.id for u in test_users]

        if not test_user_ids:
            print("삭제할 TestUser가 없습니다.")
            return

        print(f"발견된 TestUser 수: {len(test_user_ids)}")
        print(f"IDs: {test_user_ids}")

        # 2. 관련 경기 기록(Match) 먼저 삭제 (Foreign Key 에러 방지)
        # synchronize_session=False is required for IN queries in some versions/configs, good practice here
        deleted_matches = db.query(Match).filter(
            or_(
                Match.team_a_player1_id.in_(test_user_ids),
                Match.team_a_player2_id.in_(test_user_ids),
                Match.team_b_player1_id.in_(test_user_ids),
                Match.team_b_player2_id.in_(test_user_ids)
            )
        ).delete(synchronize_session=False)
        
        print(f"관련된 경기 기록 {deleted_matches}건 삭제 완료.")

        # 3. 유저 삭제
        deleted_count = db.query(Member).filter(Member.id.in_(test_user_ids)).delete(synchronize_session=False)
        
        db.commit()
        print(f"총 {deleted_count}명의 TestUser가 영구 삭제되었습니다.")
        
    except Exception as e:
        print(f"An error occurred: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    cleanup_test_users()
