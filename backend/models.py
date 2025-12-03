from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, DateTime
from sqlalchemy.orm import relationship
from database import Base  # [수정 1] 점(.) 제거: 절대 경로 사용
import datetime

class Member(Base):
    __tablename__ = "members"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), index=True)
    phone = Column(String(20), unique=True, index=True)
    birth = Column(String(10)) # YYYY format
    rank_point = Column(Integer, default=1000)
    role = Column(String(20), default="USER") # USER, ADMIN
    is_approved = Column(Boolean, default=False)
    pin = Column(String(20)) # 4-digit PIN
    
    # League Stats
    wins = Column(Integer, default=0)
    losses = Column(Integer, default=0)
    draws = Column(Integer, default=0)
    game_diff = Column(Integer, default=0)

class Match(Base):
    __tablename__ = "matches"

    id = Column(Integer, primary_key=True, index=True)
    player1_id = Column(Integer, ForeignKey("members.id"))
    player2_id = Column(Integer, ForeignKey("members.id"))
    score1 = Column(Integer)
    score2 = Column(Integer)
    # [수정 2] 최신 파이썬 표준에 맞게 시간대(Timezone) 설정
    date = Column(DateTime, default=lambda: datetime.datetime.now(datetime.timezone.utc))

    player1 = relationship("Member", foreign_keys=[player1_id])
    player2 = relationship("Member", foreign_keys=[player2_id])

class ExerciseSchedule(Base):
    __tablename__ = "schedules"

    id = Column(Integer, primary_key=True, index=True)
    member_name = Column(String(50))
    start_time = Column(String(10)) # HH:mm
    end_time = Column(String(10))   # HH:mm
    # [수정 3] 여기에 있던 중복된 start_time, end_time 라인을 삭제했습니다.
    date = Column(String(20))       # YYYY-MM-DD

class LeagueHistory(Base):
    __tablename__ = "league_history"

    id = Column(Integer, primary_key=True, index=True)
    member_id = Column(Integer, ForeignKey("members.id"))
    year = Column(Integer)
    month = Column(Integer)
    total_points = Column(Integer)
    rank = Column(Integer)

    member = relationship("Member", foreign_keys=[member_id])

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
