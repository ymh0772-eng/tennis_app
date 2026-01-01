from database import engine, Base
import models
from sqlalchemy import text

def reset_matches_table():
    print("Dropping 'matches' table...")
    with engine.connect() as conn:
        conn.execute(text("DROP TABLE IF EXISTS matches"))
        conn.commit()
    print("Table dropped.")
    
    print("Creating tables...")
    # This will create 'matches' table with the new schema defined in models.py
    # It won't affect other existing tables
    models.Base.metadata.create_all(bind=engine)
    print("Tables created.")

if __name__ == "__main__":
    reset_matches_table()
