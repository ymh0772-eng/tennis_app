from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import datetime

from . import models, schemas
from .database import SessionLocal, engine

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Dependency
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@app.post("/members/", response_model=schemas.Member)
def create_member(member: schemas.MemberCreate, db: Session = Depends(get_db)):
    db_member = models.Member(
        name=member.name, 
        phone=member.phone, 
        birth=member.birth,
        pin=member.pin
    )
    db.add(db_member)
    db.commit()
    db.refresh(db_member)
    return db_member

@app.post("/login", response_model=schemas.Member)
def login(login_req: schemas.LoginRequest, db: Session = Depends(get_db)):
    print(f"DEBUG: Login Request - Phone: '{login_req.phone}', PIN: '{login_req.pin}'")
    member = db.query(models.Member).filter(models.Member.phone == login_req.phone).first()
    if not member:
        raise HTTPException(status_code=400, detail="Phone number not found")
    if member.pin != login_req.pin:
        raise HTTPException(status_code=400, detail="Incorrect PIN")
    if not member.is_approved:
        raise HTTPException(status_code=403, detail="Account not approved yet")
    return member

@app.get("/members/", response_model=List[schemas.Member])
def read_members(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    members = db.query(models.Member).offset(skip).limit(limit).all()
    return members

@app.put("/members/{phone}/approve", response_model=schemas.Member)
def approve_member(phone: str, db: Session = Depends(get_db)):
    member = db.query(models.Member).filter(models.Member.phone == phone).first()
    if not member:
        raise HTTPException(status_code=404, detail="Member not found")
    member.is_approved = True
    db.commit()
    db.refresh(member)
    return member

@app.post("/matches", response_model=schemas.Match)
def create_match(match: schemas.MatchCreate, db: Session = Depends(get_db)):
    # 1. Create Match Record
    db_match = models.Match(
        player1_id=match.player1_id,
        player2_id=match.player2_id,
        score1=match.score1,
        score2=match.score2
    )
    db.add(db_match)

    # 2. Update Stats
    p1 = db.query(models.Member).filter(models.Member.id == match.player1_id).first()
    p2 = db.query(models.Member).filter(models.Member.id == match.player2_id).first()

    if not p1 or not p2:
        raise HTTPException(status_code=404, detail="Player not found")

    # Game Diff
    p1.game_diff += (match.score1 - match.score2)
    p2.game_diff += (match.score2 - match.score1)

    # Points & W/L/D
    if match.score1 > match.score2:
        p1.rank_point += 3
        p1.wins += 1
        p2.losses += 1
    elif match.score1 < match.score2:
        p2.rank_point += 3
        p2.wins += 1
        p1.losses += 1
    else:
        p1.rank_point += 1
        p2.rank_point += 1
        p1.draws += 1
        p2.draws += 1

    db.commit()
    db.refresh(db_match)
    return db_match

@app.get("/league/rankings", response_model=List[schemas.Member])
def get_rankings(db: Session = Depends(get_db)):
    # Sort by Points DESC, Game Diff DESC, Wins DESC
    rankings = db.query(models.Member).order_by(
        models.Member.rank_point.desc(),
        models.Member.game_diff.desc(),
        models.Member.wins.desc()
    ).all()
    return rankings

@app.post("/schedules", response_model=schemas.ScheduleResponse)
def create_schedule(schedule: schemas.ScheduleCreate, db: Session = Depends(get_db)):
    try:
        today = datetime.datetime.now().strftime("%Y-%m-%d")
        
        db_schedule = models.ExerciseSchedule(
            member_name=schedule.member_name,
            start_time=schedule.start_time,
            end_time=schedule.end_time,
            date=today
        )
        db.add(db_schedule)
        db.commit()
        db.refresh(db_schedule)
        return db_schedule
    except Exception as e:
        print(f"ERROR: {e}")
        raise HTTPException(status_code=500, detail=f"Internal Server Error: {str(e)}")

@app.get("/schedules", response_model=List[schemas.ScheduleResponse])
def read_schedules(db: Session = Depends(get_db)):
    today = datetime.datetime.now().strftime("%Y-%m-%d")
    schedules = db.query(models.ExerciseSchedule).filter(models.ExerciseSchedule.date == today).all()
    return schedules

@app.post("/tournament/generate", response_model=schemas.TournamentBracket)
def generate_tournament(db: Session = Depends(get_db)):
    # 1. Calculate Total Points from History (Last 6 months)
    # For simplicity, we just sum up all history for now as we generated only 6 months
    history = db.query(models.LeagueHistory).all()
    
    points_map = {}
    for h in history:
        if h.member_id not in points_map:
            points_map[h.member_id] = 0
        points_map[h.member_id] += h.total_points
        
    # 2. Sort Members by Total Points
    sorted_members = sorted(points_map.items(), key=lambda item: item[1], reverse=True)
    
    # 3. Pick Top 8
    top_8_ids = [m[0] for m in sorted_members[:8]]
    
    if len(top_8_ids) < 8:
        raise HTTPException(status_code=400, detail="Not enough members for a tournament (Need 8)")
        
    top_8_members = []
    for mid in top_8_ids:
        member = db.query(models.Member).filter(models.Member.id == mid).first()
        top_8_members.append(member)
        
    # 4. Create Seeds (1 vs 8, 2 vs 7, 3 vs 6, 4 vs 5)
    # QF1: 1 vs 8
    # QF2: 4 vs 5
    # QF3: 3 vs 6
    # QF4: 2 vs 7
    # This order ensures (1v8) winner meets (4v5) winner in SF1
    
    matches = []
    
    # Helper to create match
    def create_match_obj(id, p1_idx, p2_idx):
        return schemas.TournamentMatch(
            match_id=id,
            round="8강전",
            player1=top_8_members[p1_idx].name,
            player2=top_8_members[p2_idx].name
        )

    matches.append(create_match_obj(1, 0, 7)) # 1 vs 8
    matches.append(create_match_obj(2, 3, 4)) # 4 vs 5
    matches.append(create_match_obj(3, 2, 5)) # 3 vs 6
    matches.append(create_match_obj(4, 1, 6)) # 2 vs 7
    
    return schemas.TournamentBracket(matches=matches)

@app.post("/community", response_model=schemas.CommunityPostResponse)
def create_post(post: schemas.CommunityPostCreate, db: Session = Depends(get_db)):
    db_post = models.CommunityPost(
        title=post.title,
        author_name=post.author_name,
        content=post.content,
        password=post.password
    )
    db.add(db_post)
    db.commit()
    db.refresh(db_post)
    return db_post

@app.delete("/community/{post_id}")
def delete_post(post_id: int, password: str, db: Session = Depends(get_db)):
    post = db.query(models.CommunityPost).filter(models.CommunityPost.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
        
    # Verify password
    if post.password != password:
        raise HTTPException(status_code=403, detail="Incorrect password")
        
    db.delete(post)
    db.commit()
    return {"detail": "Post deleted"}

@app.get("/community", response_model=List[schemas.CommunityPostResponse])
def read_posts(db: Session = Depends(get_db)):
    # 1. Auto-delete posts older than 30 days
    cutoff_date = datetime.datetime.utcnow() - datetime.timedelta(days=30)
    db.query(models.CommunityPost).filter(models.CommunityPost.created_at < cutoff_date).delete()
    db.commit()
    
    # 2. Fetch recent posts
    posts = db.query(models.CommunityPost).order_by(models.CommunityPost.created_at.desc()).all()
    return posts
