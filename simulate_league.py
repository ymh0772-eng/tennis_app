import random
from sqlalchemy.orm import Session
from backend.database import SessionLocal
from backend import models
import datetime

def simulate_league():
    db = SessionLocal()
    members = db.query(models.Member).all()
    
    if len(members) < 2:
        print("Not enough members to simulate.")
        return

    print("Simulating 10 matches...")
    
    for _ in range(10):
        p1, p2 = random.sample(members, 2)
        
        # Simulate score (Simple 1 set match)
        # Winner usually gets 6. Loser gets 0-4, or 5 if 7-5, or 6 if 7-6.
        # Let's keep it simple: 6-X or 5-7 etc.
        
        winner_score = 6
        loser_score = random.randint(0, 4)
        
        score_str = f"{winner_score}-{loser_score}"
        
        match = models.Match(
            winner_id=p1.id,
            loser_id=p2.id,
            score=score_str,
            date=datetime.datetime.utcnow()
        )
        db.add(match)
        print(f"Match: {p1.name} vs {p2.name} -> {score_str} (Winner: {p1.name})")
    
    db.commit()
    
    # Calculate Rankings
    print("\nCalculating Rankings (Wins*3 + Draws*1 + GD)...")
    
    # Dictionary to store stats: {member_id: {'points': 0, 'gd': 0, 'wins': 0, 'draws': 0, 'losses': 0}}
    stats = {m.id: {'name': m.name, 'points': 0, 'gd': 0, 'wins': 0, 'draws': 0, 'losses': 0} for m in members}
    
    matches = db.query(models.Match).all()
    
    for m in matches:
        try:
            s1, s2 = map(int, m.score.split('-'))
        except ValueError:
            continue # Skip invalid scores
            
        # m.winner_id is the winner in DB, but let's verify score logic if we were parsing raw.
        # In this mock, we stored winner_id as p1 and score as "6-4".
        # So winner_id gets s1, loser_id gets s2?
        # Wait, score string "6-4" usually means WinnerScore-LoserScore.
        # Let's assume the format is always Winner-Loser.
        
        w_games = s1
        l_games = s2
        
        gd = w_games - l_games
        
        # Winner
        if m.winner_id in stats:
            stats[m.winner_id]['points'] += 3
            stats[m.winner_id]['wins'] += 1
            stats[m.winner_id]['gd'] += gd
            
        # Loser
        if m.loser_id in stats:
            stats[m.loser_id]['losses'] += 1
            stats[m.loser_id]['gd'] -= gd
            
    # Sort by Points desc, then GD desc
    ranked_stats = sorted(stats.values(), key=lambda x: (x['points'], x['gd']), reverse=True)
    
    print("\nLeague Standings:")
    print(f"{'Rank':<5} {'Name':<20} {'Pts':<5} {'W':<3} {'L':<3} {'D':<3} {'GD':<5}")
    print("-" * 50)
    
    for i, s in enumerate(ranked_stats):
        if s['points'] == 0 and s['wins'] == 0 and s['losses'] == 0:
            continue # Skip players who haven't played
        print(f"{i+1:<5} {s['name']:<20} {s['points']:<5} {s['wins']:<3} {s['losses']:<3} {s['draws']:<3} {s['gd']:<5}")

    db.close()

if __name__ == "__main__":
    simulate_league()
