from sqlalchemy import text
from database import engine

def fix_members_table():
    print("🔧 DB 스키마 수정 작업 시작...")
    
    # SQL 명령어: members 테이블에 is_active 컬럼 추가 (기본값 True)
    alter_query = text("ALTER TABLE members ADD COLUMN is_active BOOLEAN DEFAULT TRUE;")
    
    try:
        with engine.connect() as conn:
            conn.execute(alter_query)
            conn.commit() # 변경사항 저장
            print("✅ 성공: 'is_active' 컬럼이 members 테이블에 추가되었습니다.")
    except Exception as e:
        # 이미 컬럼이 있거나 다른 문제 발생 시
        print(f"⚠️ 경고 또는 오류: {e}")
        print("이미 컬럼이 존재할 수 있습니다. DB 상태를 확인하세요.")

if __name__ == "__main__":
    fix_members_table()
