from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

import os

# 현재 파일(database.py)이 있는 위치를 기준으로 DB 경로 설정
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "tennis_club.db")

SQLALCHEMY_DATABASE_URL = f"sqlite:///{DB_PATH}"

# SQLALCHEMY_DATABASE_URL = "mysql+pymysql://tennis_admin:9703@localhost/tennis_db"
engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
