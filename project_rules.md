# 프로젝트: Muan Tennis Club (무안 테니스 클럽)

## 1. 프로젝트 개요
- **목표:** 20명 내외 소규모 클럽을 위한 리그/토너먼트 자동화 및 근태/매칭 관리 시스템.
- **핵심 가치:** 자동화(Automation) - 순위, 대진표, 출석체크의 자동화.
- **타겟 사용자:** 40~60대 회원 (가독성 최우선).

## 2. 기술 스택 (Tech Stack)
- **Frontend:** Flutter (Dart) / Provider 패턴 / Material Design 3
- **Backend:** Python FastAPI / SQLite (20명 규모에 최적)
- **Map/GPS:** `geolocator` 패키지 (좌표 기반 출석 체크)
- **Deployment:** Ubuntu Linux 홈 서버 (Remote SSH)

## 3. 디자인 가이드 (Design System)
- **테마 (Reference):** 'Smash - Tennis App' 스타일을 참조하여 깔끔하고 모던하게 통일.
- **메인 컬러:** Forest Green (#2E7D32) - 잔디 코트 색상.
- **포인트 컬러:** Tennis Ball Yellow (#CDDC39) - 중요 버튼/알림.
- **타이포그래피:** 본문 폰트 크기 16sp 이상 유지, 굵은 서체 활용.

## 4. 데이터베이스 및 변수 명명 규칙 (Naming Convention)
- **변수명:** 영문 Full Name 사용을 원칙으로 하되, 너무 길 경우 표준 약어 사용 (가독성 확보).
  - 예: `memberName`, `phoneNumber`, `birthYear`, `matchScore`
- **회원 정보:**
  - `id` (Auto Increment), `name`, `phone`, `birth`, `rankPoint` (랭킹 점수), `role` (ADMIN/USER)

## 5. 핵심 기능 상세 명세 (Logic)

### A. 회원 관리 & 입장 (Attendance)
1.  **가입:** 사용자가 정보 입력 -> `isApproved = false`로 저장 -> 관리자가 승인 시 `true` 변경.
2.  **자동 입장 (Check-in):**
    - 앱 실행 시 GPS 좌표 확인.
    - **코트 좌표:** (무안 코트 위도, 경도 입력 필요)
    - **로직:** 코트 반경 **100m 이내** 진입 시 자동으로 "코트 입장 완료" 처리 및 DB 로그 저장.

### B. 풀리그 (Monthly League)
1.  **운영:** 매월 1일 ~ 말일.
2.  **결과 입력:** 경기 후 '승자'가 스코어 입력.
3.  **순위 갱신:**
    - 실시간 반영하되, **매월 1일 00:00**에 '지난달 랭킹'으로 확정 짓고 점수 초기화(옵션).
    - **산정 공식:** (승수 × 3) + (무승부 × 1) + 득실차.

### C. 토너먼트 (Bianual Tournament)
1.  **시즌:** 4월, 10월 (연 2회).
2.  **자동 대진표:**
    - 직전 6개월 누적 랭킹 1위~20위를 기준으로 **상위/하위 그룹 자동 분리**.
    - **Snake Draft 방식**으로 팀 밸런스 자동 배정 (예: 1위와 20위가 같은 팀).

### D. 운동 약속 (Scheduler)
1.  **입력:** 시작 시간, 종료 시간 선택.
2.  **초기화:** 매주 월요일 00:00에 지난주 약속 데이터 **자동 삭제 (Soft Delete)**.

## 6. 개발 및 테스트 가이드
1.  **Mock Data (검증용):**
    - 개발 시작 시, `MockDataGenerator` 클래스를 만들어 **임의의 회원 20명(이름, 전번, 랭킹점수 포함)**을 DB에 강제로 주입하고 시작할 것.
    - 이 20명으로 풀리그 순위가 제대로 바뀌는지 시뮬레이션 후 UI 작업 진행.
2.  **메모리 갱신 절차:**
    - 서브 메뉴(기능) 하나가 완성될 때마다 `project_status.md` 파일을 업데이트하여 진행 상황을 기록할 것.
3.  - **언어 규칙 (Language):**
  - 앱의 모든 UI 텍스트(버튼, 라벨, 알림창 등)는 반드시 **'한국어(Korean)'**로 작성한다.
  - 예: 'Login' -> '로그인', 'Logout' -> '로그아웃', 'Home' -> '홈', 'Rank' -> '순위'
  - 주석뿐만 아니라 사용자에게 보이는 모든 글자는 한글이어야 함.