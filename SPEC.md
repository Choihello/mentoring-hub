# 멘토링 허브 — 프로젝트 스펙 문서

> 광운대학교 NCI창업패키지사업단 멘토링 관리 시스템
> 기술 스택: 단일 HTML 파일 (Vanilla JS) + Supabase (PostgreSQL + Auth + Realtime + Storage)
> 제작: 최광범 (neo@kw.ac.kr)

---

## [1] 역할별 기능 목록

### 🎓 멘토 기능

| # | 기능 | 설명 |
|---|------|------|
| 1 | 가용 일정 등록 | 날짜, 시간대(09:00~22:00 중 복수 선택), 장소/방식(Zoom, Google Meet, 대면-센터 회의실, 대면-멘토 사무실, 기타)을 지정하여 멘티가 예약 가능한 슬롯 생성 |
| 2 | 일정 삭제 | 예약되지 않은(available) 슬롯을 삭제 (status를 'deleted'로 변경) |
| 3 | 미니 달력 조회 | 월별 달력에서 가용 슬롯이 있는 날짜(파란 점), 예약된 날짜(노란색)를 시각적으로 확인 |
| 4 | 등록된 시간 목록 조회 | 가용 슬롯과 매칭된(pending/booked) 슬롯을 분리된 테이블로 확인 |
| 5 | 예약 신청 수락 | pending 상태의 세션을 upcoming(확정)으로 변경, 슬롯 상태를 booked로 변경 |
| 6 | 예약 신청 거절 | pending 세션을 rejected로 변경, 슬롯을 다시 available로 복원, session_log에 기록 |
| 7 | 확정 세션 완료 처리 | upcoming 세션을 completed로 변경 (멘토링 시작 시간 이후만 가능), 완료 후 일지 작성 모달 자동 오픈 |
| 8 | 세션 취소 | upcoming 또는 pending 세션을 취소, 슬롯 복원, session_log에 기록 |
| 9 | 멘토링 일지 작성 | 유형(창업전략/기술개발/마케팅영업/투자재무/법률특허/기타), 소요시간(30분~2시간 이상), 세부 장소, 주요 상담 내용(50자 이상 필수), 멘티 현황 및 문제점(20자 이상 필수), 다음 멘토링 계획(20자 이상 필수), 종합 평가(5단계), 사진 첨부(필수, 10MB 이하) |
| 10 | 일지 임시 저장 | localStorage에 세션별 드래프트 저장, 재진입 시 자동 복원 |
| 11 | 일지 수정 | 이미 제출된 일지를 수정 모드로 열어 재제출 |
| 12 | 일지 상세 보기 | 제출된 일지의 전체 내용 + 멘티 피드백을 모달로 확인 |
| 13 | 공지사항 열람 | '전체' 또는 '멘토만' 대상 공지를 조회, 읽음/안읽음 상태 관리 (localStorage 기반) |
| 14 | 요청 제출 | 관리자에게 유형(일정변경/멘토변경/기타문의), 제목, 내용으로 요청 전달 |
| 15 | 관리자 회신 확인 | 요청에 대한 관리자 회신을 확인하고 읽음 처리 |
| 16 | 관리자 발신 메시지 확인 | 관리자가 직접 보낸 메시지를 확인하고 읽음 처리 |
| 17 | 멘티 피드백 열람 | 완료된 세션의 멘티 피드백(평가, 도움이 된 점)을 예약 현황 카드에서 확인 |

### 🚀 멘티 기능

| # | 기능 | 설명 |
|---|------|------|
| 1 | 멘토 목록 조회 | 활성 멘토를 가용 슬롯 수 기준으로 정렬하여 표시 (이름, 분야, 소속, 소개글, 가용 슬롯 수) |
| 2 | 멘토 선택 | 멘토 카드 클릭 시 해당 멘토의 가용 시간(미래 시간만)을 날짜별 그룹으로 표시 |
| 3 | 멘토링 예약 | 슬롯 선택 후 멘토링 주제/요청사항(10자 이상 필수) 입력, book_session RPC를 통한 동시성 안전 예약 |
| 4 | 중복 예약 방지 | 같은 멘토에 진행 중인 예약(pending/upcoming)이 있으면 추가 예약 차단 |
| 5 | 내 멘토링 내역 조회 | 진행 중(pending/upcoming)과 완료(completed) 세션을 2컬럼으로 분리 표시 |
| 6 | 세션 상태 확인 | pending 시 "멘토 확인 대기 중", upcoming 시 장소/방식 포함 확정 안내 표시 |
| 7 | 신청 취소 | pending 또는 upcoming 세션을 취소, 슬롯 복원 |
| 8 | 멘토링 피드백 작성 | 완료된 세션에 만족도(5단계), 도움이 된 점(필수), 개선 바라는 점(선택) 제출 |
| 9 | 공지사항 열람 | '전체' 또는 '멘티만' 대상 공지를 조회, 읽음/안읽음 상태 관리 |
| 10 | 요청 제출 | 관리자에게 유형(일정변경/멘토변경/기타문의), 제목, 내용으로 요청 전달 |
| 11 | 관리자 회신 확인 | 요청에 대한 관리자 회신을 확인하고 읽음 처리 |
| 12 | 관리자 발신 메시지 확인 | 관리자가 직접 보낸 메시지를 확인하고 읽음 처리 |

### 📊 관리자 기능

| # | 기능 | 설명 |
|---|------|------|
| 1 | 대시보드 통계 확인 | 등록 멘토수, 등록 멘티수, 가용 슬롯, 신청 대기, 확정 세션, 완료 세션, 제출된 일지, 일지 미제출 카운트 표시 |
| 2 | 기간별 실적 요약 | 이번 주/이번 달/월별 조회/주차별 조회/전체 누적 탭으로 세션 통계 + 멘토별 세션/일지 집계 테이블 표시 |
| 3 | 멘토-멘티 매칭 현황 | 세션 기반 매칭 쌍별 총 횟수/완료/확정/대기 카운트 테이블 |
| 4 | 전체 세션 목록 | 기간(전체/이번 주/이번 달) + 상태(전체/대기/확정/완료) 필터링, 멘토/멘티/일시/상태/일지/취소 버튼 표시 |
| 5 | 일지 미제출 목록 | 완료 세션 중 일지 미제출 건을 멘토/멘티/일시/세션ID와 함께 경고 표시 |
| 6 | 세션 강제 취소 | 대기/확정 세션을 관리자 권한으로 취소, session_log에 'admin_cancelled' 기록 |
| 7 | 멘토 추가 | 이름(필수), 분야(필수), 소속, 이메일(필수), 소개글 입력, users 테이블에 로그인 계정 자동 생성 (upsertUser) |
| 8 | 멘토 활성/비활성 토글 | active 필드 변경으로 멘티 예약 화면 노출 제어 |
| 9 | 멘토 노출 중단 | 멘토를 비활성화하여 예약 화면에서 숨김 |
| 10 | 멘토 관리 테이블 | 이름/분야/소속/전체 세션/완료 세션/일지율/활성 상태 표시 |
| 11 | 멘티 추가 | 이름(필수), 팀명(필수), 이메일(필수) 입력, users 테이블에 로그인 계정 자동 생성 |
| 12 | 멘티 삭제 | 소프트 삭제(is_deleted), 진행 중인 세션 자동 취소 + 슬롯 복원, session_log에 기록 |
| 13 | 멘티 관리 테이블 | 이름/팀명/이메일/세션수/예정+완료 카운트 표시 |
| 14 | 일지 목록 조회 | 멘토 필터, 멘티 필터, 날짜 범위(시작~종료) 필터로 전체 일지 검색 |
| 15 | 일지 상세 보기 | 일지 전체 필드 + 사진 + 멘티 피드백을 모달로 확인 |
| 16 | 요청 관리 — 회신 | 멘토/멘티 요청에 회신 입력, 상태를 '처리완료'로 변경 |
| 17 | 관리자 메시지 발송 | 특정 멘토 또는 멘티에게 직접 메시지 발송 (수신자 선택, 유형, 제목, 내용) |
| 18 | 발신 메시지 내역 | 관리자가 보낸 메시지의 읽음/미확인 상태 확인 |
| 19 | 공지 작성 | 대상(전체/멘토만/멘티만), 제목, 내용, 중요 여부 설정 후 공지 등록 |
| 20 | 공지 삭제 | 소프트 삭제(is_deleted)로 공지 숨김 |
| 21 | Supabase 연동 설정 | Supabase URL, Anon Key, Google OAuth 클라이언트 ID 입력 및 연결 테스트 |
| 22 | 역할 전환 미리보기 | 관리자가 멘토/멘티 화면을 읽기 전용으로 미리보기 (첫 번째 멘토/멘티 기준), 데이터 필터링 적용 |
| 23 | Supabase 대시보드 바로가기 | 외부 링크로 Supabase 프로젝트 대시보드 열기 |

---

## [2] 화면 목록

### 공통 화면

| 화면 ID | 화면명 | 설명 |
|---------|--------|------|
| `screen-login` | 로그인 화면 | Supabase 연동 시 Google 로그인 모드, 미연동 시 데모 모드(역할 카드 선택) |
| — | 토스트 알림 | 화면 하단 우측에 성공/에러/정보 메시지 2.8초 표시 |

**로그인 화면 동작:**
- Supabase 연동 O: `login-google-mode` 표시 → Google One Tap → Supabase Auth signInWithIdToken → `get_my_account` RPC로 역할 확인 → `get_app_bundle` RPC로 데이터 로드 → 역할별 화면 진입
- Supabase 연동 X: `login-demo-mode` 표시 → 멘토/멘티/담당자 카드 클릭 → 데모 데이터 시드 → 역할별 화면 진입
- 새로고침 시 Supabase Auth 세션 자동 복원, 실패 시 sessionStorage 기반 데모 세션 복원

### 멘토 화면

| 화면 ID | 화면명 | 주요 인터랙션 |
|---------|--------|-------------|
| `page-mentor-schedule` | 가용 일정 등록 | 미니 달력 월 이동(changeMonth), 시간 추가 버튼(openAddSlotModal) → 날짜 선택 → 시간대 복수 선택 → 장소 선택 → 추가, 슬롯 삭제(deleteSlot) |
| `page-mentor-sessions` | 예약 현황 | 신청 대기(pending) 세션 수락(confirmSession)/거절(rejectSession), 확정(upcoming) 세션 완료 처리(completeSession)/취소(cancelSession), 완료 세션에서 일지 작성/보기, 멘티 피드백 확인 |
| `page-mentor-journal` | 멘토링 일지 | 작성 대기(completed+일지 미제출) 세션 → 일지 작성 모달, 제출 완료 세션 → 상세 보기/수정 |
| `page-mentor-notices` | 공지사항 | 공지 목록 조회(중요 공지 상단 고정), 공지 클릭 → 상세 모달 + 읽음 처리, 안읽은 공지 빨간 점 표시 |
| `page-mentor-request` | 요청하기 | 관리자 메시지 수신 목록(읽음 처리), 새 요청 작성(유형/제목/내용) → 제출, 내 요청 내역 + 관리자 회신 확인(읽음 처리) |

### 멘티 화면

| 화면 ID | 화면명 | 주요 인터랙션 |
|---------|--------|-------------|
| `page-mentee-book` | 멘토 예약하기 | 멘토 카드 목록(가용 슬롯 수 표시, 소개글 표시) → 멘토 선택(selectMentor) → 날짜별 가용 시간 표시 → 시간 클릭(openBookModal) → 주제 입력(10자 이상) → 예약 확정(confirmBooking) |
| `page-mentee-sessions` | 내 멘토링 내역 | 진행 중(pending/upcoming): 상태 안내 + 취소 버튼, 완료(completed): 피드백 작성(openFeedbackModal) 또는 완료 표시 |
| `page-mentee-notices` | 공지사항 | 멘토와 동일한 구조, '전체' + '멘티만' 공지 표시 |
| `page-mentee-request` | 요청하기 | 멘토와 동일한 구조 |

### 관리자 화면

| 화면 ID | 화면명 | 주요 인터랙션 |
|---------|--------|-------------|
| `page-admin-dashboard` | 전체 현황 대시보드 | 통계 카드(8개), Supabase 대시보드 바로가기, 기간별 실적(이번 주/이번 달/월별/주차별/전체, 탭 전환 setPeriodTab), 멘토-멘티 매칭 현황 테이블, 일지 미제출 목록, 세션 목록(기간+상태 필터, 관리자 취소 adminCancelSession, 일지 보기) |
| `page-admin-mentors` | 멘토 관리 | 멘토 추가 모달(openModal 'modal-add-mentor') → addMentor, 테이블에서 활성/비활성 토글(toggleMentorActive), 노출 중단(deleteMentor) |
| `page-admin-mentees` | 멘티 관리 | 멘티 추가 모달(openModal 'modal-add-mentee') → addMentee, 테이블에서 삭제(deleteMentee, 세션 자동 취소) |
| `page-admin-journals` | 일지 목록 | 멘토 필터, 멘티 필터, 날짜 범위 필터, 초기화, 일지 카드 + 상세 보기(viewJournalById) |
| `page-admin-requests` | 요청 관리 | 관리자 메시지 발송(sendAdminMessage: 수신자 선택/유형/제목/내용), 발신 메시지 내역(읽음 상태), 대기중 요청 회신(replyRequest), 처리완료 요청 내역 |
| `page-admin-notices` | 공지 작성 | 새 공지 작성(대상/제목/내용/중요 여부) → createNotice, 등록된 공지 목록(중요 공지 상단, 삭제 deleteNotice) |
| `page-settings` | Supabase 연동 | Supabase URL/Anon Key/Google Client ID 입력, 연결 테스트(testConnection), 설정 저장(saveSettings → localStorage), 데이터 테이블 구조 안내 |

### 모달 목록

| 모달 ID | 용도 | 트리거 |
|---------|------|--------|
| `modal-add-slot` | 가용 시간 추가 | 멘토 일정 페이지 "시간 추가" 버튼 |
| `modal-journal` | 멘토링 일지 작성/수정 | 일지 작성/수정 버튼, 세션 완료 처리 후 자동 |
| `modal-book` | 멘토링 예약 확인 | 멘티 가용 시간 클릭 |
| `modal-feedback` | 멘토링 피드백 작성 | 멘티 완료 세션 "피드백 작성" 버튼 |
| `modal-add-mentor` | 멘토 추가 | 관리자 멘토 관리 "멘토 추가" 버튼 |
| `modal-add-mentee` | 멘티 추가 | 관리자 멘티 관리 "멘티 추가" 버튼 |
| `modal-notice-detail` | 공지사항 상세 | 멘토/멘티 공지 카드 클릭 |
| `modal-journal-view` | 멘토링 일지 상세 보기 | 일지 보기 버튼 |

---

## [3] 데이터 구조

### Supabase 테이블 전체 목록

#### 1. `users` — 로그인 계정 관리

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | uuid (PK, 자동생성) | 계정 고유 ID |
| `email` | text (NOT NULL) | Google 이메일 (소문자) |
| `role` | text (NOT NULL) | 'admin', 'mentor', 'mentee' 중 하나 (CHECK) |
| `name` | text (기본 '') | 사용자 이름 |
| `linked_id` | text (기본 '') | mentors.id 또는 mentees.id에 대한 참조 |
| `created_at` | timestamptz (자동) | 생성 시각 |

- **UNIQUE 제약조건**: (email, role) — 같은 이메일로 역할별 1개 계정
- **인덱스**: `idx_users_email` ON email

#### 2. `mentors` — 멘토 프로필

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | text (PK) | 멘토 ID (클라이언트 생성, 예: 'm' + timestamp) |
| `name` | text (NOT NULL) | 이름 |
| `field` | text (기본 '') | 전문 분야 |
| `org` | text (기본 '') | 소속/직함 |
| `email` | text (기본 '') | 이메일 |
| `bio` | text (기본 '') | 멘토 소개 (멘티에게 표시) |
| `active` | boolean (기본 true) | 활성 여부 (false이면 멘티 예약 화면에서 숨김) |
| `is_deleted` | boolean (기본 false) | 소프트 삭제 |
| `created_at` | timestamptz (자동) | 생성 시각 |

#### 3. `mentees` — 멘티 프로필

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | text (PK) | 멘티 ID (클라이언트 생성, 예: 'me' + timestamp) |
| `name` | text (NOT NULL) | 이름 |
| `team` | text (기본 '') | 팀명 |
| `email` | text (기본 '') | 이메일 |
| `is_deleted` | boolean (기본 false) | 소프트 삭제 |
| `created_at` | timestamptz (자동) | 생성 시각 |

#### 4. `slots` — 멘토 가용 시간

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | text (PK) | 슬롯 ID |
| `mentor_id` | text (NOT NULL, FK → mentors.id) | 멘토 참조 |
| `date` | text (NOT NULL) | 날짜 (YYYY-MM-DD 문자열) |
| `time` | text (NOT NULL) | 시간 (HH:MM 문자열) |
| `location` | text (기본 '') | 장소/방식 |
| `status` | text (기본 'available') | 'available', 'pending', 'booked', 'deleted' (CHECK) |
| `session_id` | text (기본 '') | 연결된 세션 ID |
| `created_at` | timestamptz (자동) | 생성 시각 |

- **인덱스**: `idx_slots_mentor` ON mentor_id

#### 5. `sessions` — 멘토링 세션

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | text (PK) | 세션 ID (RPC에서 'sess' + uuid 형식 생성) |
| `mentor_id` | text (NOT NULL, FK → mentors.id) | 멘토 참조 |
| `mentee_id` | text (NOT NULL, FK → mentees.id) | 멘티 참조 |
| `slot_id` | text (FK → slots.id) | 슬롯 참조 |
| `date` | text (NOT NULL) | 날짜 |
| `time` | text (NOT NULL) | 시간 |
| `location` | text (기본 '') | 장소/방식 |
| `topic` | text (기본 '') | 멘토링 주제/요청사항 |
| `status` | text (기본 'pending') | 'pending', 'upcoming', 'completed', 'cancelled', 'rejected' (CHECK) |
| `has_journal` | boolean (기본 false) | 일지 제출 여부 |
| `has_feedback` | boolean (기본 false) | 피드백 제출 여부 |
| `created_at` | timestamptz (자동) | 생성 시각 |

- **인덱스**: `idx_sessions_mentor` ON mentor_id, `idx_sessions_mentee` ON mentee_id, `idx_sessions_status` ON status

#### 6. `journals` — 멘토링 일지

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | text (PK) | 일지 ID |
| `session_id` | text (FK → sessions.id) | 세션 참조 |
| `mentor_id` | text (FK → mentors.id) | 멘토 참조 |
| `mentee_id` | text (FK → mentees.id) | 멘티 참조 |
| `date` | text (기본 '') | 멘토링 날짜 |
| `type` | text (기본 '') | 멘토링 유형 |
| `duration` | text (기본 '') | 소요 시간 |
| `detail_location` | text (기본 '') | 세부 장소 |
| `content` | text (기본 '') | 주요 상담 내용 |
| `issues` | text (기본 '') | 멘티 현황 및 문제점 |
| `next_plan` | text (기본 '') | 다음 멘토링 계획 |
| `rating` | text (기본 '') | 종합 평가 |
| `photo_url` | text (기본 '') | 사진 URL (Supabase Storage) |
| `submitted_at` | timestamptz (자동) | 제출 시각 |

- **인덱스**: `idx_journals_mentor` ON mentor_id, `idx_journals_session` ON session_id

#### 7. `feedbacks` — 멘티 피드백

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | text (PK) | 피드백 ID |
| `session_id` | text (FK → sessions.id) | 세션 참조 |
| `mentor_id` | text (FK → mentors.id) | 멘토 참조 |
| `mentee_id` | text (FK → mentees.id) | 멘티 참조 |
| `rating` | text (기본 '') | 만족도 평가 |
| `good` | text (기본 '') | 도움이 된 점 |
| `improve` | text (기본 '') | 개선 바라는 점 |
| `submitted_at` | timestamptz (자동) | 제출 시각 |

#### 8. `session_log` — 세션 이력 (취소 로그)

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | serial (PK) | 자동 증가 ID |
| `session_id` | text (NOT NULL) | 세션 ID |
| `action` | text (NOT NULL) | 액션 ('cancelled', 'rejected', 'admin_cancelled', 'cancel') |
| `cancelled_by` | text (기본 '') | 취소 주체 ('mentor', 'mentee', 'admin', 'admin(멘티삭제)') |
| `cancelled_at` | timestamptz (자동) | 취소 시각 |

#### 9. `requests` — 요청/메시지

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | text (PK) | 요청 ID |
| `author_id` | text (기본 '') | 작성자 ID (멘토/멘티) |
| `author_name` | text (기본 '') | 작성자 이름 |
| `author_role` | text (기본 '') | 작성자 역할 |
| `type` | text (기본 '') | 유형 ('일정변경', '멘토변경', '기타문의', '관리자발신') |
| `title` | text (기본 '') | 제목 |
| `content` | text (기본 '') | 내용 |
| `status` | text (기본 '대기중') | 상태 ('대기중', '처리중', '처리완료', '전송완료') |
| `reply` | text (기본 '') | 관리자 회신 내용 |
| `reply_read` | boolean (기본 false) | 회신 읽음 여부 |
| `sender` | text (기본 '') | 발신자 (관리자 발신 시 '관리자') |
| `receiver_id` | text (기본 '') | 수신자 ID |
| `receiver` | text (기본 '') | 수신자 이름 |
| `receiver_role` | text (기본 '') | 수신자 역할 |
| `message_type` | text (기본 '') | 메시지 유형 (관리자 발신 시: '일반 안내', '일정 안내', '주의사항', '기타') |
| `created_at` | timestamptz (자동) | 생성 시각 |

#### 10. `notices` — 공지사항

| 컬럼 | 타입 | 설명 |
|------|------|------|
| `id` | text (PK) | 공지 ID |
| `target` | text (기본 '전체') | '전체', '멘토만', '멘티만' (CHECK) |
| `title` | text (기본 '') | 제목 |
| `content` | text (기본 '') | 내용 |
| `is_important` | boolean (기본 false) | 중요 공지 여부 (상단 고정 + 빨간 뱃지) |
| `is_deleted` | boolean (기본 false) | 소프트 삭제 |
| `created_at` | timestamptz (자동) | 생성 시각 |

#### Storage 버킷

| 버킷명 | 용도 | 공개 여부 |
|--------|------|-----------|
| `journal-photos` | 멘토링 일지 사진 첨부 | public (누구나 읽기 가능) |

- 업로드 경로: `journals/journal-{sessionId}-{timestamp}.{ext}`
- 업로드 권한: mentor 또는 admin만 가능

### RPC 함수

#### 1. `get_user_email()`
- **목적**: 현재 인증된 사용자의 이메일 반환
- **반환**: text (소문자 이메일)
- **동작**: `auth.jwt()->>'email'`에서 추출

#### 2. `get_effective_user_account()`
- **목적**: 현재 인증 사용자의 역할/linked_id/이름을 결정
- **반환**: TABLE(role text, linked_id text, name text)
- **동작**: users 테이블에서 이메일 매칭 → 역할 우선순위(admin > mentor > mentee) → mentors/mentees 테이블 존재 검증 → 없으면 mentors/mentees 테이블에서 직접 이메일 매칭(fallback)

#### 3. `get_user_role()` / `get_user_linked_id()` / `get_user_name()`
- **목적**: `get_effective_user_account()`에서 개별 필드 추출
- **반환**: text

#### 4. `get_my_account()`
- **목적**: 로그인 시 현재 계정 정보를 JSON으로 반환
- **반환**: json `{ ok, error?, account?: { email, role, linkedId, name } }`
- **에러 케이스**: unauthenticated, account_not_found

#### 5. `book_session(p_slot_id text, p_mentee_id text, p_topic text)`
- **목적**: 멘토링 예약 (동시성 안전)
- **반환**: json `{ ok, error?, session?: { id, mentorId, ... } }`
- **동작**:
  1. 역할 검증 (mentee 또는 admin만)
  2. 본인 계정 검증 (mentee인 경우)
  3. `SELECT ... FOR UPDATE`로 슬롯 행 잠금
  4. 슬롯 available 상태 검증
  5. 멘토 active 상태 검증
  6. 같은 멘토에 중복 예약(pending/upcoming) 방지
  7. 세션 INSERT + 슬롯 status를 pending으로 UPDATE

#### 6. `get_app_bundle()`
- **목적**: 역할에 따라 필터링된 전체 데이터를 한번의 호출로 반환
- **반환**: json `{ ok, data: { mentors, mentees, slots, sessions, journals, feedbacks, requests, notices } }`
- **역할별 데이터 범위**:
  - **admin**: 모든 테이블의 모든 행
  - **mentor**: 본인 멘토 데이터 + 본인 세션에 연결된 멘티만 + 본인 슬롯/세션/일지/피드백 + 본인 관련 요청 + '전체'/'멘토만' 공지
  - **mentee**: 활성 멘토(또는 세션 연결된 멘토) + 본인 멘티 데이터 + 삭제되지 않은 활성 멘토 슬롯 + 본인 세션/피드백 + 본인 관련 요청 + '전체'/'멘티만' 공지 (일지는 빈 배열)

#### 7. `apply_batch_operations(p_operations jsonb)`
- **목적**: 여러 데이터 변경을 하나의 트랜잭션으로 실행
- **매개변수**: JSON 배열, 각 항목에 action/sheet/id/data/updates 포함
- **지원 액션**:
  - `append`: mentors, mentees, journals, feedbacks, sessionLog에 INSERT
  - `update`: mentors, mentees, slots, sessions, journals, requests, notices에 UPDATE
  - `upsertUser`: users 테이블에 UPSERT (email+role 기준)
- **반환**: json `{ ok }`

### RLS 정책 요약

| 테이블 | SELECT | INSERT | UPDATE |
|--------|--------|--------|--------|
| `users` | admin은 전체, 일반 사용자는 본인 이메일만 | admin만 | admin만 |
| `mentors` | admin 전체, 본인 ID, 또는 삭제/비활성 아닌 멘토 | admin만 | admin만 |
| `mentees` | admin 전체, 본인 ID, 또는 멘토가 세션으로 연결된 멘티 | admin만 | admin만 |
| `slots` | admin 전체, 본인 멘토 슬롯, 멘티는 삭제 아닌 활성 멘토 슬롯 | admin 또는 본인 멘토 | admin 또는 본인 멘토 |
| `sessions` | admin 전체, 본인이 멘토 또는 멘티인 세션 | admin 또는 본인 멘티 | admin 또는 본인 멘토 또는 본인 멘티 |
| `journals` | admin 전체 또는 본인 멘토 | admin 또는 본인 멘토 | admin 또는 본인 멘토 |
| `feedbacks` | admin 전체 또는 본인 멘토/멘티 | admin 또는 본인 멘티 | (정책 없음 — 수정 불가) |
| `session_log` | admin만 | 인증된 모든 사용자 | (정책 없음) |
| `requests` | admin 전체 또는 본인이 author/receiver | admin 또는 본인 역할/ID 일치 | admin 또는 본인이 author/receiver |
| `notices` | admin 전체 또는 삭제 아닌 대상별(전체/멘토만/멘티만) | admin만 | admin만 |
| `storage.objects (journal-photos)` | 인증 사용자 모두 + 공개(public) | mentor 또는 admin만 | (정책 없음) |

---

## [4] 역할 간 상호작용 흐름

### 멘토링 세션 라이프사이클

```
[관리자]                    [멘토]                      [멘티]
   |                          |                           |
   | 멘토/멘티 등록             |                           |
   | (users + mentors/mentees) |                           |
   |                          |                           |
   |                    슬롯 등록                          |
   |                 (slots: available)                    |
   |                          |                           |
   |                          |                    멘토 선택 + 슬롯 선택
   |                          |                    book_session RPC 호출
   |                          |              (slots: pending, sessions: pending)
   |                          |                           |
   |                    신청 수락 (confirmSession)          |
   |              (sessions: upcoming, slots: booked)       |
   |                          |                           |
   |                          |      ← Realtime 알림 →     |
   |                          |     "멘토가 수락했습니다"      |
   |                          |                           |
   |                   [멘토링 진행]                        |
   |                          |                           |
   |                  완료 처리 (completeSession)           |
   |               (sessions: completed)                   |
   |                          |                           |
   |                  일지 작성 (submitJournal)             |
   |            (journals INSERT, has_journal=true)         |
   |                          |                           |
   |                          |                    피드백 작성 (submitFeedback)
   |                          |            (feedbacks INSERT, has_feedback=true)
   |                          |                           |
```

**대안 경로:**
- **멘토 거절**: pending → rejected, 슬롯 → available (session_log 기록)
- **멘토 취소**: upcoming → cancelled, 슬롯 → available (session_log 기록)
- **멘티 취소**: pending/upcoming → cancelled, 슬롯 → available (session_log 기록)
- **관리자 강제 취소**: pending/upcoming → cancelled (session_log에 admin_cancelled 기록)
- **관리자 멘티 삭제 시**: 해당 멘티의 모든 활성 세션 자동 취소

### 요청/메시지 흐름

```
[멘토/멘티] → submitRequest → requests INSERT (status: 대기중)
                                    ↓
[관리자] ← 요청 관리 화면에서 확인 (뱃지: 대기중 건수)
                                    ↓
[관리자] → replyRequest → requests UPDATE (reply + status: 처리완료)
                                    ↓
[멘토/멘티] ← 요청하기 화면에서 회신 확인 (🔴 새 회신 + 뱃지)
         → markReplyRead → reply_read = true

[관리자] → sendAdminMessage → requests INSERT (type: 관리자발신, status: 전송완료)
                                    ↓
[멘토/멘티] ← 요청하기 화면 상단 관리자 메시지 섹션에서 확인
         → markReplyRead → reply_read = true
```

### 공지사항 흐름

```
[관리자] → createNotice → notices INSERT (target: 전체/멘토만/멘티만)
                                ↓
[멘토/멘티] ← 공지사항 화면에서 확인 (target 필터링)
           (안읽은 공지: 빨간 점 표시, 사이드바 뱃지)
           → openNoticeDetail → localStorage에 읽음 기록

[관리자] → deleteNotice → notices UPDATE (is_deleted: true)
                                ↓
[멘토/멘티] ← 목록에서 즉시 사라짐
```

### 이메일 알림 시점

현재 구현에 이메일 알림 기능은 **없습니다**. 모든 알림은 앱 내 실시간 감지로 처리됩니다:
- 멘티: Realtime으로 세션 상태 변경 감지 → 토스트 메시지 ("멘토가 수락했습니다" / "신청이 거절되었습니다")
- 멘토: Realtime으로 새 예약 감지 → 토스트 메시지 ("새 멘토링 신청 N건!")

### Realtime 이벤트

**Supabase Realtime 구독 테이블** (postgres_changes, schema: public):
1. `sessions` — 세션 상태 변경 감지
2. `slots` — 슬롯 상태 변경 감지
3. `requests` — 요청/메시지 변경 감지
4. `notices` — 공지사항 변경 감지
5. `mentors` — 멘토 정보 변경 감지
6. `mentees` — 멘티 정보 변경 감지
7. `journals` — 일지 변경 감지
8. `feedbacks` — 피드백 변경 감지

**동작 방식:**
- 모든 변경 이벤트(`*`: INSERT, UPDATE, DELETE)를 단일 채널 `db-realtime`으로 수신
- 변경 수신 시 500ms 디바운스 후 `_silentRefresh()` 호출 (전체 데이터 재로드 via `get_app_bundle`)
- Realtime 연결 실패 시 60초 간격 폴링 fallback 활성화
- 사용자가 폼 입력 중이면 데이터 리로드 후 페이지 리렌더를 블러 이벤트까지 지연

---

## [5] 현재 알려진 미완성 기능 또는 버그

### 미완성 기능

1. **이메일 알림 미구현**: 세션 수락/거절/취소, 새 예약, 관리자 메시지 등에 대한 이메일 알림이 없음. 멘토/멘티가 앱에 접속해야만 변경 사항을 확인할 수 있음.

2. **피드백 수정 불가**: `feedbacks` 테이블에 UPDATE RLS 정책이 없어 한번 제출한 피드백은 수정할 수 없음. 프론트엔드에도 수정 UI가 없음.

3. **멘토 프로필 수정 불가 (멘토 본인)**: 멘토가 자신의 이름, 분야, 소속, 소개글을 직접 수정하는 기능이 없음. mentors 테이블의 UPDATE는 admin만 가능.

4. **멘티 프로필 수정 불가 (멘티 본인)**: 멘티가 자신의 이름, 팀명을 직접 수정하는 기능이 없음.

5. **멘토 완전 삭제(hard delete) 불가**: 관리자가 멘토를 "노출 중단"(비활성화)만 가능하고, 실제 삭제(is_deleted 처리)하는 UI가 없음. `deleteMentor` 함수는 단순히 active=false로만 설정.

6. **검색 기능 없음**: 멘토, 멘티, 세션, 일지 등에 대한 텍스트 검색 기능이 없음.

7. **페이지네이션 없음**: 모든 목록(세션, 일지, 요청 등)이 전량 로드되어 데이터가 많아지면 성능 저하 가능.

8. **일지 삭제 기능 없음**: 잘못 제출된 일지를 삭제하는 기능이 없음 (수정만 가능).

9. **피드백 삭제 기능 없음**: 잘못 제출된 피드백을 삭제하는 기능이 없음.

10. **멘토링 일정 변경 기능 없음**: 확정된 세션의 날짜/시간/장소를 직접 변경하는 기능 없음. 취소 후 재예약만 가능.

11. **다중 관리자 지원 미흡**: 관리자 추가/삭제 UI가 없음. 관리자 계정은 DB에 직접 INSERT해야 함.

12. **사진 삭제 기능 없음**: 일지에 첨부된 사진을 Supabase Storage에서 삭제하는 기능이 없음. 수정 시 새 사진으로 대체만 가능.

### 잠재적 버그/제한사항

13. **날짜/시간이 text 타입**: slots.date, sessions.date, journals.date 등이 PostgreSQL의 date/time 타입이 아닌 text로 저장됨. 범위 검색이나 정렬 시 문자열 비교에 의존하여 잘못된 형식 입력 시 오류 가능.

14. **시간대 처리**: 클라이언트에서 `+09:00` (KST) 하드코딩으로 시간 비교. 다른 시간대의 사용자가 접속하면 시간 불일치 가능.

15. **낙관적 업데이트 롤백 불완전**: 대부분의 쓰기 작업이 낙관적 업데이트(로컬 즉시 반영 → 서버 동기화)를 사용하나, 롤백 시 `_rebuildIndex()`를 호출하지 않는 경우가 일부 있어 인덱스 캐시와 실제 데이터 불일치 가능.

16. **데모 모드에서 데이터 비영속**: 데모 모드의 모든 변경 사항은 브라우저 새로고침 시 초기 시드 데이터로 리셋됨 (localStorage 아닌 메모리에만 저장).

17. **session_log SELECT 제한**: session_log는 admin만 SELECT 가능하여 멘토/멘티가 자신의 세션 취소 이력을 확인할 수 없음.

18. **관리자 미리보기에서 쓰기 차단**: `ensureAuthorized` 함수에서 `isPreviewMode()` 체크로 미리보기 중 데이터 변경을 차단하지만, 일부 함수에서 `ensureAuthorized`를 호출하지 않는 경우가 있을 수 있음.

19. **중복 이메일 검증 불완전**: 멘토/멘티 추가 시 프론트엔드에서만 이메일 중복 체크. DB 레벨의 unique 제약조건은 없어, 동시 추가 시 중복 가능.

20. **Realtime 전체 데이터 재로드**: 어떤 테이블의 어떤 행이 변경되든 항상 `get_app_bundle` RPC로 전체 데이터를 재로드함. 데이터가 커지면 비효율적.

21. **`period-custom-controls` 초기 상태**: HTML에서 `style="display:none;margin-bottom:12px;display:flex;..."` 으로 display 속성이 두 번 선언되어 실질적으로 항상 flex로 표시됨 (의도는 none).

22. **멘티에게 일지 비공개**: `get_app_bundle`에서 mentee 역할에 journals를 빈 배열로 반환. 멘티는 자신의 멘토링 일지 내용을 확인할 수 없음.

## [6] 신규 추가 기능 (리뉴얼에서 새로 구현)

### 매칭 프로세스

**플로우 A — 멘티 신청 기반**
- 멘티가 희망분야 / 희망일정 / 요청사항 입력 후 신청
- 담당자가 매칭 대시보드에서 멘토 선택 후 제안
- 멘토가 앱에서 수락 또는 거절
- 수락 시 매칭 확정 → 기존 일정조율 프로세스 시작
- 거절 시 담당자에게 알림 → 재매칭

**플로우 B — 담당자 직접 매칭**
- 담당자가 멘토 + 멘티 직접 선택 후 즉시 확정
- 멘토 동의 단계 없음
- 확정 즉시 멘토/멘티에게 이메일 + 앱 내 알림

**신규 테이블**

match_requests:
- id, mentee_id, preferred_field,
  preferred_schedule, request_note,
  status(대기중/제안됨/확정/거절), created_at

match_proposals:
- id, mentor_id, mentee_id,
  request_id(nullable, 플로우A만),
  flow_type('mentee_request'/'admin_direct'),
  mentor_response(대기/수락/거절, 플로우A만),
  admin_memo(nullable), status(제안중/확정/거절),
  created_at

**신규 화면**

멘티:
- 매칭 신청 화면
  (희망분야 태그 선택 / 희망일정 복수선택 / 요청사항)
- 매칭 현황 확인 (대기중/제안됨/확정 상태 표시)

멘토:
- 매칭 알림 화면
  (제안된 멘티 정보 확인 / 수락·거절 버튼)
- 미확인 제안 건수 사이드바 뱃지 표시

관리자:
- 매칭 관리 화면 (탭 3개)
  탭1: 멘티 신청 목록 (플로우A)
  탭2: 매칭 현황 전체 (필터: 상태/플로우 구분)
  탭3: 직접 매칭 (플로우B)

### 이메일 알림

알림 수신 이메일:
- 멘토/멘티 프로필에 notification_email 필드 추가
- 비워두면 로그인 이메일로 발송

발송 시점:
1. 멘토에게 매칭 제안 (플로우A)
2. 멘토/멘티에게 매칭 확정 (플로우A 수락)
3. 멘토/멘티에게 매칭 확정 (플로우B)
4. 담당자에게 멘토 거절 알림 (플로우A)
5. 세션 수락/거절/취소 알림
6. 관리자 메시지 수신 알림

이메일 발송: Supabase Edge Functions 사용

### 프로필 수정

- 멘토 본인 프로필 수정 가능
  (이름, 분야, 소속, 소개글, 알림 수신 이메일)
- 멘티 본인 프로필 수정 가능
  (이름, 팀명, 알림 수신 이메일)

### 데이터 타입 개선

- slots.date → date 타입으로 변경
- sessions.date → date 타입으로 변경
- journals.date → date 타입으로 변경

### 미완성 기능 중 이번에 해결

- 이메일 알림 구현
- 멘토/멘티 프로필 수정
- 날짜 타입 정규화
- 멘토 소프트 삭제(is_deleted) UI 추가

### 이번에 해결하지 않는 것 (추후 고도화)

- 페이지네이션
- 검색 기능
- 피드백 수정/삭제
- 일지 삭제
- 멘토링 일정 변경
- 다중 관리자 지원

---

## [7] 디자인 방향

기술 스택: React + Supabase + Supabase Auth + Netlify
디자인 레퍼런스: Linear + 토스 스타일
테마: 라이트 모드, 미니멀, 여백 넉넉
포인트 컬러: #2D5016 (딥 그린)
보조 컬러: #4A7C2F, #D4E8C4
폰트: Pretendard
사이드바: 라이트 톤 (콘텐츠 영역과 통일)
카드: 흰색 배경 + 0.5px 테두리
버튼: 포인트 컬러 기반
날짜 포맷: 2026년 3월 24일 오후 2:35 (ISO 원시값 금지)
이메일 마스킹: z***@gmail.com 형식

## [8] 정책 사항

- 멘티에게 멘토링 일지 비공개
  (멘티는 본인 피드백만 확인 가능)
- 멘토링 일지 사진 첨부 필수
- 주요 상담 내용 50자 이상 필수
- 멘티 현황 및 문제점 20자 이상 필수
- 다음 멘토링 계획 20자 이상 필수
```

---

