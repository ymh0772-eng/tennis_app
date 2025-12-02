from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
import datetime
import re  # 정규표현식 모듈 추가 (전화번호 정제용)

# 절대 경로 import로 통일 (점 제거)
import models
import schemas
from database import SessionLocal, engine

# DB 테이블 생성
models.Base.metadata.create_all(bind=engine)

app = FastAPI()

# CORS 설정 (앱 접속 허용)
from fastapi.middleware.cors import CORSMiddleware

from fastapi.staticfiles import StaticFiles

app.mount("/images", StaticFiles(directory="uploads"), name="images")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 모든 주소에서 접속 허용
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# DB 세션 의존성 함수
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- 1. 유틸리티 함수 (전화번호 숫자만 추출) ---
def sanitize_phone(phone: str) -> str:
    """하이픈, 공백 등을 제거하고 숫자만 남김"""
    if not phone:
        return ""
    return re.sub(r'[^0-9]', '', str(phone))

# --- 2. 회원 관리 API ---

@app.post("/members/", response_model=schemas.Member)
def create_member(member: schemas.MemberCreate, db: Session = Depends(get_db)):
    # 전화번호 정제
    clean_phone = sanitize_phone(member.phone)
    
    # 중복 체크
    existing_member = db.query(models.Member).filter(models.Member.phone == clean_phone).first()
    if existing_member:
        raise HTTPException(status_code=400, detail="이미 등록된 전화번호입니다.")

    db_member = models.Member(
        name=member.name, 
        phone=clean_phone,  # 정제된 번호 저장
        birth=member.birth,
        pin=member.pin
    )
    db.add(db_member)
    db.commit()
    db.refresh(db_member)
    return db_member

@app.post("/login", response_model=schemas.Member)
def login(login_req: schemas.LoginRequest, db: Session = Depends(get_db)):
    try:
        # 전화번호 정제 (하이픈 제거)
        clean_phone = sanitize_phone(login_req.phone)
        print(f"DEBUG: Login Attempt - Phone: '{clean_phone}', PIN: '{login_req.pin}'")
        
        member = db.query(models.Member).filter(models.Member.phone == clean_phone).first()
        
        if not member:
            raise HTTPException(status_code=400, detail="등록되지 않은 전화번호입니다.")
        
        if member.pin != login_req.pin:
            raise HTTPException(status_code=400, detail="비밀번호가 틀렸습니다.")
            
        if not member.is_approved:
            # 403 Forbidden: 승인 대기 중 (앱에서 PendingScreen으로 이동)
            raise HTTPException(status_code=403, detail="승인 대기 중입니다.")
            
        return member
        
    except Exception as e:
        print(f"LOGIN ERROR: {str(e)}")
        # 앱이 죽지 않도록 500 에러 대신 명확한 메시지 전달
        raise HTTPException(status_code=500, detail=f"로그인 처리 중 오류: {str(e)}")

@app.get("/members/", response_model=List[schemas.Member])
def read_members(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    members = db.query(models.Member).offset(skip).limit(limit).all()
    return members

@app.put("/members/{phone}/approve", response_model=schemas.Member)
def approve_member(phone: str, db: Session = Depends(get_db)):
    clean_phone = sanitize_phone(phone)
    member = db.query(models.Member).filter(models.Member.phone == clean_phone).first()
    if not member:
        raise HTTPException(status_code=404, detail="회원을 찾을 수 없습니다.")
    member.is_approved = True
    db.commit()
    db.refresh(member)
    return member

# --- 3. 리그 및 경기 API ---

@app.post("/matches", response_model=schemas.Match)
def create_match(match: schemas.MatchCreate, db: Session = Depends(get_db)):
    # 1. 경기 기록 생성
    db_match = models.Match(
        player1_id=match.player1_id,
        player2_id=match.player2_id,
        score1=match.score1,
        score2=match.score2
    )
    db.add(db_match)

    # 2. 선수 스탯 업데이트
    p1 = db.query(models.Member).filter(models.Member.id == match.player1_id).first()
    p2 = db.query(models.Member).filter(models.Member.id == match.player2_id).first()

    if not p1 or not p2:
        raise HTTPException(status_code=404, detail="선수 정보를 찾을 수 없습니다.")

    # 득실차 계산
    p1.game_diff += (match.score1 - match.score2)
    p2.game_diff += (match.score2 - match.score1)

    # 승점 및 승무패 기록 (승3, 무1, 패0)
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
    # 순위 산정: 승점 > 득실차 > 승수 내림차순
    rankings = db.query(models.Member).order_by(
        models.Member.rank_point.desc(),
        models.Member.game_diff.desc(),
        models.Member.wins.desc()
    ).all()
    return rankings

# --- 4. 운동 약속 (Schedule) API ---

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
        print(f"SCHEDULE ERROR: {e}")
        raise HTTPException(status_code=500, detail=f"스케줄 등록 실패: {str(e)}")

@app.get("/schedules", response_model=List[schemas.ScheduleResponse])
def read_schedules(db: Session = Depends(get_db)):
    today = datetime.datetime.now().strftime("%Y-%m-%d")
    # 오늘 날짜의 스케줄만 조회
    schedules = db.query(models.ExerciseSchedule).filter(models.ExerciseSchedule.date == today).all()
    return schedules

# --- 5. 토너먼트 (Tournament) API ---

@app.post("/tournament/generate", response_model=schemas.TournamentBracket)
def generate_tournament(db: Session = Depends(get_db)):
    # 1. 최근 6개월 기록 합산 (단순화를 위해 전체 합산)
    history = db.query(models.LeagueHistory).all()
    
    points_map = {}
    for h in history:
        if h.member_id not in points_map:
            points_map[h.member_id] = 0
        points_map[h.member_id] += h.total_points
        
    # 2. 점수순 정렬
    sorted_members = sorted(points_map.items(), key=lambda item: item[1], reverse=True)
    
    # 3. 상위 8명 선발
    top_8_ids = [m[0] for m in sorted_members[:8]]
    
    if len(top_8_ids) < 8:
        # 데이터가 부족할 경우 현재 멤버에서 보충 (에러 방지용)
        remaining_members = db.query(models.Member).filter(models.Member.id.notin_(top_8_ids)).limit(8 - len(top_8_ids)).all()
        for rm in remaining_members:
            top_8_ids.append(rm.id)
            
        if len(top_8_ids) < 8:
             raise HTTPException(status_code=400, detail="토너먼트 인원 부족 (최소 8명 필요)")
        
    top_8_members = []
    for mid in top_8_ids:
        member = db.query(models.Member).filter(models.Member.id == mid).first()
        top_8_members.append(member)
        
    # 4. 시드 배정 (1위 vs 8위, 2위 vs 7위 ...)
    matches = []
    
    def create_match_obj(id, p1_idx, p2_idx):
        return schemas.TournamentMatch(
            match_id=id,
            round="8강전",
            player1=top_8_members[p1_idx].name,
            player2=top_8_members[p2_idx].name
        )

    # 8강 대진표 (승자가 4강에서 만나는 구조 고려)
    matches.append(create_match_obj(1, 0, 7)) # 1위 vs 8위
    matches.append(create_match_obj(2, 3, 4)) # 4위 vs 5위
    matches.append(create_match_obj(3, 2, 5)) # 3위 vs 6위
    matches.append(create_match_obj(4, 1, 6)) # 2위 vs 7위
    
    return schemas.TournamentBracket(matches=matches)

# --- 6. 커뮤니티 (Community) API ---

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
        raise HTTPException(status_code=404, detail="게시글을 찾을 수 없습니다.")
        
    # 비밀번호 검증
    if post.password != password:
        raise HTTPException(status_code=403, detail="비밀번호가 틀렸습니다.")
        
    db.delete(post)
    db.commit()
    return {"detail": "게시글이 삭제되었습니다."}

@app.get("/community", response_model=List[schemas.CommunityPostResponse])
def read_posts(db: Session = Depends(get_db)):
    # 1. 30일 지난 게시글 자동 삭제
    cutoff_date = datetime.datetime.now() - datetime.timedelta(days=30)
    db.query(models.CommunityPost).filter(models.CommunityPost.created_at < cutoff_date).delete()
    db.commit()
    
    # 2. 최신순 조회
    posts = db.query(models.CommunityPost).order_by(models.CommunityPost.created_at.desc()).all()
    return posts

# --- 7. 갤러리 (Gallery) API ---

import shutil
import uuid
import os
from fastapi import File, UploadFile, Form

@app.post("/gallery", response_model=schemas.GalleryResponse)
def upload_gallery(
    file: UploadFile = File(...),
    uploader_name: str = Form(...),
    file_type: str = Form(...), # 'IMAGE' or 'VIDEO'
    db: Session = Depends(get_db)
):
    # Create uploads directory if not exists
    os.makedirs("uploads", exist_ok=True)
    
    # Generate unique filename
    file_extension = file.filename.split(".")[-1]
    unique_filename = f"{uuid.uuid4()}.{file_extension}"
    file_path = f"uploads/{unique_filename}"
    
    # Save file
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    # Save to DB
    db_gallery = models.Gallery(
        uploader_name=uploader_name,
        file_type=file_type,
        file_path=file_path,
        thumbnail_path=None
    )
    db.add(db_gallery)
    db.commit()
    db.refresh(db_gallery)
    
    return db_gallery

@app.get("/gallery", response_model=List[schemas.GalleryResponse])
def read_gallery(db: Session = Depends(get_db)):
    return db.query(models.Gallery).order_by(models.Gallery.created_at.desc()).all()

@app.delete("/gallery/{gallery_id}")
def delete_gallery(gallery_id: int, db: Session = Depends(get_db)):
    gallery = db.query(models.Gallery).filter(models.Gallery.id == gallery_id).first()
    if not gallery:
        raise HTTPException(status_code=404, detail="Gallery item not found")
    
    # Optional: Delete file from disk
    # if os.path.exists(gallery.file_path):
    #     os.remove(gallery.file_path)

    db.delete(gallery)
    db.commit()
    return {"detail": "Gallery item deleted"}
