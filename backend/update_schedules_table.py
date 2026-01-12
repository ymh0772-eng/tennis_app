from database import engine, Base
from models import Schedule
from sqlalchemy import text

def reset_schedules_table():
    with engine.connect() as conn:
        print("Dropping 'schedules' table...")
        try:
            conn.execute(text("DROP TABLE IF EXISTS schedules"))
            conn.commit()
            print("Dropped.")
        except Exception as e:
            print(f"Error dropping table: {e}")

    print("Creating new 'schedules' table...")
    Schedule.__table__.create(engine)
    print("Created.")

if __name__ == "__main__":
    reset_schedules_table()
