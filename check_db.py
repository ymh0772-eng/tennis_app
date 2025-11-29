from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from backend.models import Member, Base

engine = create_engine('sqlite:///tennis_club.db')
Session = sessionmaker(bind=engine)
session = Session()

members = session.query(Member).all()
print(f"Total members: {len(members)}")
for m in members:
    print(f"Name: {m.name}, Phone: {m.phone}, PIN: {m.pin}, Approved: {m.is_approved}")
