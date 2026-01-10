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

class LoginResponse(BaseModel):
    access_token: str
    token_type: str
    id: int
    name: str
    phone: str
    role: str
    is_approved: bool

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
    team_a_player1_id: int
    team_a_player2_id: int
    team_b_player1_id: int
    team_b_player2_id: int
    score_team_a: int
    score_team_b: int

class MatchCreate(MatchBase):
    pass

class Match(MatchBase):
    id: int
    date: datetime

    class Config:
        orm_mode = True

class MatchHistoryResponse(BaseModel):
    id: int
    date: datetime
    score_team_a: int
    score_team_b: int
    team_a_names: str
    team_b_names: str
    
    class Config:
        orm_mode = True

from datetime import date as date_type

from datetime import time, date

class ScheduleBase(BaseModel):
    member_name: str
    start_time: str
    end_time: str

class ScheduleCreate(BaseModel):
    start_time: time
    end_time: time
    date: date

    class Config:
        json_schema_extra = {
            "example": {
                "start_time": "10:00:00",
                "end_time": "12:00:00",
                "date": "2024-05-20"
            }
        }

class Schedule(ScheduleBase):
    id: int
    member_id: int
    date: date_type

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
