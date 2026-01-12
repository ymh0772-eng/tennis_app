from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, DateTime, Date
from sqlalchemy.orm import relationship
from database import Base  # [수정 1] 점(.) 제거: 절대 경로 사용
import datetime

class Member(Base):
    __tablename__ = "members"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), index=True)
    phone = Column(String(20), unique=True, index=True)
    birth = Column(String(10)) # YYYY format
    pin = Column(String(20)) # 4-digit PIN
    # 등급 및 승인 여부
    role = Column(String, default="MEMBER")
    is_approved = Column(Boolean, default=False)
    
    # 리그 스탯
    rank_point = Column(Integer, default=0) # 승점
    game_diff = Column(Integer, default=0)  # 득실차
    wins = Column(Integer, default=0)
    draws = Column(Integer, default=0)
    losses = Column(Integer, default=0)

    # [신규 추가] 소프트 삭제(임시 삭제) 플래그
    # True: 활동 중, False: 삭제 대기(휴지통)
    is_active = Column(Boolean, default=True)

class Match(Base):
    __tablename__ = "matches"

    id = Column(Integer, primary_key=True, index=True)
    
    # Team A
    team_a_player1_id = Column(Integer, ForeignKey("members.id"))
    team_a_player2_id = Column(Integer, ForeignKey("members.id"))
    
    # Team B
    team_b_player1_id = Column(Integer, ForeignKey("members.id"))
    team_b_player2_id = Column(Integer, ForeignKey("members.id"))
    
    score_team_a = Column(Integer)
    score_team_b = Column(Integer)
    
    # [수정 2] 최신 파이썬 표준에 맞게 시간대(Timezone) 설정
    date = Column(DateTime, default=lambda: datetime.datetime.now(datetime.timezone.utc))

    team_a_player1 = relationship("Member", foreign_keys=[team_a_player1_id])
    team_a_player2 = relationship("Member", foreign_keys=[team_a_player2_id])
    team_b_player1 = relationship("Member", foreign_keys=[team_b_player1_id])
    team_b_player2 = relationship("Member", foreign_keys=[team_b_player2_id])

class Schedule(Base):
    __tablename__ = "schedules"

    id = Column(Integer, primary_key=True, index=True)
    member_id = Column(Integer, ForeignKey("members.id"))
    member_name = Column(String(50))
    start_time = Column(String(10)) # HH:mm
    end_time = Column(String(10))   # HH:mm
    date = Column(Date)             # YYYY-MM-DD
    
    member = relationship("Member")

# [신규 추가] 지난달 기록 보관용 테이블
class LeagueHistory(Base):
    __tablename__ = "league_histories"
    
    id = Column(Integer, primary_key=True, index=True)
    member_id = Column(Integer, ForeignKey("members.id"))
    
    # 기록 시점 (예: 2026년 1월)
    year = Column(Integer)
    month = Column(Integer)
    
    # 당시 최종 성적
    total_points = Column(Integer)
    final_wins = Column(Integer)
    final_losses = Column(Integer)
    final_diff = Column(Integer) # 당시 득실차
    
    recorded_at = Column(DateTime, default=datetime.datetime.utcnow)
    
    # 멤버와 연결
    member = relationship("Member")

class CommunityPost(Base):
    __tablename__ = "community_posts"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(100))
    author_name = Column(String(50))
    content = Column(String(2000))
    password = Column(String(20))
    # [수정 2] 시간대 설정 적용
    created_at = Column(DateTime, default=lambda: datetime.datetime.now(datetime.timezone.utc))

class Gallery(Base):
    __tablename__ = "gallery"

    id = Column(Integer, primary_key=True, index=True)
    uploader_name = Column(String(50))
    file_type = Column(String(20)) # 'IMAGE' or 'VIDEO'
    file_path = Column(String(255))
    thumbnail_path = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.datetime.now(datetime.timezone.utc))
