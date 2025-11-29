from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, DateTime
from sqlalchemy.orm import relationship
from .database import Base
import datetime

class Member(Base):
    __tablename__ = "members"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    phone = Column(String, unique=True, index=True)
    birth = Column(String) # YYYY format
    rank_point = Column(Integer, default=1000)
    role = Column(String, default="USER") # USER, ADMIN
    is_approved = Column(Boolean, default=False)
    pin = Column(String) # 4-digit PIN
    
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
    date = Column(DateTime, default=datetime.datetime.utcnow)

    player1 = relationship("Member", foreign_keys=[player1_id])
    player2 = relationship("Member", foreign_keys=[player2_id])

class ExerciseSchedule(Base):
    __tablename__ = "schedules"

    id = Column(Integer, primary_key=True, index=True)
    member_name = Column(String)
    start_time = Column(String) # HH:mm
    end_time = Column(String)   # HH:mm
    start_time = Column(String) # HH:mm
    end_time = Column(String)   # HH:mm
    date = Column(String)       # YYYY-MM-DD

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
    title = Column(String)
    author_name = Column(String)
    content = Column(String)
    password = Column(String)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
