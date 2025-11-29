from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.models import Member, Base

engine = create_engine('sqlite:///tennis_club.db')
Session = sessionmaker(bind=engine)
session = Session()

# Update the first member's PIN to 1234
member = session.query(Member).first()
if member:
    member.pin = "1234"
    session.commit()
    print(f"Updated PIN for {member.name} ({member.phone}) to 1234")
else:
    print("No members found")
