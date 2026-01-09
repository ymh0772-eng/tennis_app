from sqlalchemy.orm import Session
from database import SessionLocal
import models
import datetime

def reset_league_and_cleanup():
    """
    매월 말일 실행:
    1. 현재 성적을 LeagueHistory에 백업
    2. 현재 성적 0으로 초기화
    3. 탈퇴 대기(is_active=False) 회원 영구 삭제
    """
    db: Session = SessionLocal()
    try:
        print("⏰ [Scheduler] 월말 정산 및 정리 작업 시작...")
        
        # 날짜 계산 (지난달 기록으로 저장)
        now = datetime.datetime.now()
        record_year = now.year
        record_month = now.month 

        members = db.query(models.Member).all()
        
        for member in members:
            # 1. 탈퇴 대기 회원 -> 영구 삭제 (이제 진짜 지움)
            if not member.is_active:
                print(f"💀 [Cleanup] 탈퇴 대기 회원 영구 삭제: {member.name}")
                db.delete(member)
                continue # 삭제했으니 다음으로

            # 2. 활동 회원 -> 기록 백업
            history = models.LeagueHistory(
                member_id=member.id,
                year=record_year,
                month=record_month,
                total_points=member.rank_point,
                final_wins=member.wins,
                final_losses=member.losses,
                final_diff=member.game_diff
            )
            db.add(history)

            # 3. 점수 초기화 (새 시즌 시작)
            member.rank_point = 0
            member.wins = 0
            member.draws = 0
            member.losses = 0
            member.game_diff = 0
            
        db.commit()
        print("✅ [Scheduler] 월말 정산 완료!")
        
    except Exception as e:
        print(f"❌ [Scheduler Error] {e}")
        db.rollback()
    finally:
        db.close()
