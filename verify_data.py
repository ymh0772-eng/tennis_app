from sqlalchemy.orm import Session
from backend.database import SessionLocal
from backend import models

def verify_data():
    db = SessionLocal()
    members = db.query(models.Member).order_by(models.Member.rank_point.desc()).all()
    
    print(f"Total members: {len(members)}")
    print("Top 5 Members by Rank:")
    for i, member in enumerate(members[:5]):
        print(f"{i+1}. {member.name} - {member.rank_point} pts")
    
    db.close()

if __name__ == "__main__":
    verify_data()
