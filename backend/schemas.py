from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class MemberBase(BaseModel):
    name: str
    phone: str
    birth: str

class MemberCreate(MemberBase):
    pin: str

class LoginRequest(BaseModel):
    phone: str
    pin: str

class Member(MemberBase):
    id: int
    rank_point: int
    role: str
    is_approved: bool
    wins: int
    losses: int
    draws: int
    game_diff: int

    class Config:
        orm_mode = True

class MatchBase(BaseModel):
    player1_id: int
    player2_id: int
    score1: int
    score2: int

class MatchCreate(MatchBase):
    pass

class Match(MatchBase):
    id: int
    date: datetime

    class Config:
        orm_mode = True

class ScheduleBase(BaseModel):
    member_name: str
    start_time: str
    end_time: str

class ScheduleCreate(ScheduleBase):
    pass

class ScheduleResponse(ScheduleBase):
    id: int
    date: str

    class Config:
        orm_mode = True

class TournamentMatch(BaseModel):
    match_id: int
    round: str # 'QF', 'SF', 'F'
    player1: str
    player2: str

class TournamentBracket(BaseModel):
    matches: List[TournamentMatch]

class CommunityPostBase(BaseModel):
    title: str
    author_name: str
    content: str

class CommunityPostCreate(CommunityPostBase):
    password: str

class CommunityPostResponse(CommunityPostBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True

class GalleryBase(BaseModel):
    uploader_name: str
    file_type: str

class GalleryCreate(GalleryBase):
    pass

class GalleryResponse(GalleryBase):
    id: int
    file_path: str
    thumbnail_path: Optional[str] = None
    created_at: datetime

    class Config:
        orm_mode = True
