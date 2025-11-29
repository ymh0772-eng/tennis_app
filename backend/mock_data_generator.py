import random
from sqlalchemy.orm import Session
from .database import SessionLocal, engine
from . import models

# Ensure tables exist
models.Base.metadata.create_all(bind=engine)

def generate_mock_data():
    db = SessionLocal()
    
    # Check if admin already exists
    admin = db.query(models.Member).filter(models.Member.phone == "010-4733-1067").first()
    if not admin:
        print("Creating Admin Account...")
        admin_user = models.Member(
            name="관리자(총무)",
            phone="010-4733-1067",
            birth="1970", # Fixed as requested
            rank_point=2000, # High rank for admin?
            role="ADMIN",
            is_approved=True,
            pin="9703"
        )
        db.add(admin_user)
        db.commit()
        print("Admin Account Created.")
    else:
        print("Admin Account already exists.")

    # Check if other data already exists
    if db.query(models.Member).count() > 1: # >1 because admin might be there
        print("Mock data already exists. Skipping generation.")
        db.close()
        return

    first_names = ["Min-su", "Ji-hoon", "Hyun-woo", "Dong-hyuk", "Sang-min", "Chul-soo", "Young-ho", "Jae-sung", "Sung-hoon", "Kyung-chul", "Min-ji", "Ji-hye", "Soo-jin", "Eun-young", "Mi-kyung", "Hye-jin", "Ji-young", "Ye-jin", "Seo-yeon", "Ha-eun"]
    last_names = ["Kim", "Lee", "Park", "Choi", "Jung", "Kang", "Cho", "Yoon", "Jang", "Lim", "Han", "Oh", "Seo", "Shin", "Kwon", "Hwang", "Ahn", "Song", "Jeon", "Hong"]

    print("Generating 20 mock members...")
    
    for i in range(20):
        name = f"{random.choice(last_names)} {random.choice(first_names)}"
        # Ensure unique names for simplicity in this mock, though not strictly required by DB
        # But let's just append a number if we want to be safe or just rely on probability.
        # Given the lists, collisions are possible. Let's make it simple:
        name = f"Member {i+1}" 
        
        # Real-ish names are better for "Wow" factor.
        # Let's use a fixed list of 20 full names to avoid collisions and look good.
        full_names = [
            "Kim Min-su", "Lee Ji-hoon", "Park Hyun-woo", "Choi Dong-hyuk", "Jung Sang-min",
            "Kang Chul-soo", "Cho Young-ho", "Yoon Jae-sung", "Jang Sung-hoon", "Lim Kyung-chul",
            "Han Min-ji", "Oh Ji-hye", "Seo Soo-jin", "Shin Eun-young", "Kwon Mi-kyung",
            "Hwang Hye-jin", "Ahn Ji-young", "Song Ye-jin", "Jeon Seo-yeon", "Hong Ha-eun"
        ]
        name = full_names[i]

        phone = f"010-{random.randint(1000, 9999)}-{random.randint(1000, 9999)}"
        birth = str(random.randint(1960, 1985)) # 40-60s target
        rank_point = random.randint(800, 1500)
        
        member = models.Member(
            name=name,
            phone=phone,
            birth=birth,
            rank_point=rank_point,
            role="USER",
            is_approved=True
        )
        db.add(member)
    
    db.commit()
    db.commit()
    print("Successfully generated 20 mock members.")

    # Generate League History (Last 6 months: May - Oct)
    print("Generating League History...")
    members = db.query(models.Member).all()
    months = [5, 6, 7, 8, 9, 10]
    
    for month in months:
        # Shuffle members to randomize monthly performance
        # But give weight to Admin and some members to be consistently good
        monthly_performance = []
        for m in members:
            base_score = random.randint(0, 30)
            if m.role == 'ADMIN' or m.name in ["Kim Min-su", "Lee Ji-hoon"]:
                base_score += 20 # Boost for top players
            monthly_performance.append({'member': m, 'score': base_score})
        
        # Sort by score to determine rank
        monthly_performance.sort(key=lambda x: x['score'], reverse=True)
        
        for rank, perf in enumerate(monthly_performance):
            history = models.LeagueHistory(
                member_id=perf['member'].id,
                year=2025, # Assuming current year context or just fixed
                month=month,
                total_points=perf['score'],
                rank=rank + 1
            )
            db.add(history)
            
    db.commit()
    print("Successfully generated League History.")
    db.close()

if __name__ == "__main__":
    generate_mock_data()
