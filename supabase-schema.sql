-- ═══════════════════════════════════════════════════════
-- 멘토링 허브 — Supabase 테이블 스키마
-- Google Sheets 구조를 PostgreSQL로 변환
-- ═══════════════════════════════════════════════════════

-- 0. Auth helpers used by RLS and frontend RPCs
SET check_function_bodies = off;

CREATE OR REPLACE FUNCTION get_user_email()
RETURNS text AS $$
  SELECT lower(auth.jwt()->>'email');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_effective_user_account()
RETURNS TABLE(role text, linked_id text, name text) AS $$
  WITH email_ctx AS (
    SELECT get_user_email() AS email
  ),
  valid_users AS (
    SELECT
      u.role,
      COALESCE(u.linked_id, '') AS linked_id,
      COALESCE(NULLIF(u.name, ''), '') AS name,
      CASE u.role
        WHEN 'admin' THEN 0
        WHEN 'mentor' THEN 1
        WHEN 'mentee' THEN 2
        ELSE 9
      END AS role_rank,
      u.created_at
    FROM public.users u
    CROSS JOIN email_ctx e
    WHERE e.email IS NOT NULL
      AND lower(u.email) = e.email
      AND (
        u.role = 'admin'
        OR (
          u.role = 'mentor'
          AND EXISTS (
            SELECT 1
            FROM public.mentors m
            WHERE m.id = u.linked_id
              AND COALESCE(m.is_deleted, false) = false
          )
        )
        OR (
          u.role = 'mentee'
          AND EXISTS (
            SELECT 1
            FROM public.mentees me
            WHERE me.id = u.linked_id
              AND COALESCE(me.is_deleted, false) = false
          )
        )
      )
  ),
  chosen_user AS (
    SELECT role, linked_id, name
    FROM valid_users
    ORDER BY role_rank, created_at DESC
    LIMIT 1
  ),
  mentor_fallback AS (
    SELECT
      'mentor'::text AS role,
      m.id AS linked_id,
      COALESCE(m.name, '') AS name
    FROM public.mentors m
    CROSS JOIN email_ctx e
    WHERE e.email IS NOT NULL
      AND lower(m.email) = e.email
      AND COALESCE(m.is_deleted, false) = false
    ORDER BY m.created_at DESC
    LIMIT 1
  ),
  mentee_fallback AS (
    SELECT
      'mentee'::text AS role,
      me.id AS linked_id,
      COALESCE(me.name, '') AS name
    FROM public.mentees me
    CROSS JOIN email_ctx e
    WHERE e.email IS NOT NULL
      AND lower(me.email) = e.email
      AND COALESCE(me.is_deleted, false) = false
    ORDER BY me.created_at DESC
    LIMIT 1
  )
  SELECT role, linked_id, name FROM chosen_user
  UNION ALL
  SELECT role, linked_id, name
  FROM mentor_fallback
  WHERE NOT EXISTS (SELECT 1 FROM chosen_user)
  UNION ALL
  SELECT role, linked_id, name
  FROM mentee_fallback
  WHERE NOT EXISTS (SELECT 1 FROM chosen_user)
    AND NOT EXISTS (SELECT 1 FROM mentor_fallback)
  LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_user_role()
RETURNS text AS $$
  SELECT role FROM get_effective_user_account() LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_user_linked_id()
RETURNS text AS $$
  SELECT linked_id FROM get_effective_user_account() LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_user_name()
RETURNS text AS $$
  SELECT name FROM get_effective_user_account() LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION get_my_account()
RETURNS json AS $$
DECLARE
  v_email text := get_user_email();
  v_account record;
BEGIN
  IF v_email IS NULL OR v_email = '' THEN
    RETURN json_build_object('ok', false, 'error', 'unauthenticated');
  END IF;

  SELECT * INTO v_account
  FROM get_effective_user_account();

  IF NOT FOUND THEN
    RETURN json_build_object('ok', false, 'error', 'account_not_found');
  END IF;

  RETURN json_build_object(
    'ok', true,
    'account', json_build_object(
      'email', v_email,
      'role', v_account.role,
      'linkedId', COALESCE(v_account.linked_id, ''),
      'name', COALESCE(v_account.name, '')
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ═══ 1. users (로그인 계정 관리) ═══
CREATE TABLE public.users (
  id          uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  email       text NOT NULL,
  role        text NOT NULL CHECK (role IN ('admin','mentor','mentee')),
  name        text DEFAULT '',
  linked_id   text DEFAULT '',
  created_at  timestamptz DEFAULT now(),
  UNIQUE(email, role)
);

-- ═══ 2. mentors (멘토 프로필) ═══
CREATE TABLE public.mentors (
  id          text PRIMARY KEY,
  name        text NOT NULL,
  field       text DEFAULT '',
  org         text DEFAULT '',
  email       text DEFAULT '',
  bio         text DEFAULT '',
  active      boolean DEFAULT true,
  is_deleted  boolean DEFAULT false,
  created_at  timestamptz DEFAULT now()
);

-- ═══ 3. mentees (멘티 프로필) ═══
CREATE TABLE public.mentees (
  id          text PRIMARY KEY,
  name        text NOT NULL,
  team        text DEFAULT '',
  email       text DEFAULT '',
  is_deleted  boolean DEFAULT false,
  created_at  timestamptz DEFAULT now()
);

-- ═══ 4. slots (멘토 가용 시간) ═══
CREATE TABLE public.slots (
  id          text PRIMARY KEY,
  mentor_id   text NOT NULL REFERENCES public.mentors(id),
  date        text NOT NULL,
  time        text NOT NULL,
  location    text DEFAULT '',
  status      text DEFAULT 'available' CHECK (status IN ('available','pending','booked','deleted')),
  session_id  text DEFAULT '',
  created_at  timestamptz DEFAULT now()
);

-- ═══ 5. sessions (멘토링 세션) ═══
CREATE TABLE public.sessions (
  id          text PRIMARY KEY,
  mentor_id   text NOT NULL REFERENCES public.mentors(id),
  mentee_id   text NOT NULL REFERENCES public.mentees(id),
  slot_id     text REFERENCES public.slots(id),
  date        text NOT NULL,
  time        text NOT NULL,
  location    text DEFAULT '',
  topic       text DEFAULT '',
  status      text DEFAULT 'pending' CHECK (status IN ('pending','upcoming','completed','cancelled','rejected')),
  has_journal  boolean DEFAULT false,
  has_feedback boolean DEFAULT false,
  created_at  timestamptz DEFAULT now()
);

-- ═══ 6. journals (멘토링 일지) ═══
CREATE TABLE public.journals (
  id              text PRIMARY KEY,
  session_id      text REFERENCES public.sessions(id),
  mentor_id       text REFERENCES public.mentors(id),
  mentee_id       text REFERENCES public.mentees(id),
  date            text DEFAULT '',
  type            text DEFAULT '',
  duration        text DEFAULT '',
  detail_location text DEFAULT '',
  content         text DEFAULT '',
  issues          text DEFAULT '',
  next_plan       text DEFAULT '',
  rating          text DEFAULT '',
  photo_url       text DEFAULT '',
  submitted_at    timestamptz DEFAULT now()
);

-- ═══ 7. feedbacks (멘티 피드백) ═══
CREATE TABLE public.feedbacks (
  id          text PRIMARY KEY,
  session_id  text REFERENCES public.sessions(id),
  mentor_id   text REFERENCES public.mentors(id),
  mentee_id   text REFERENCES public.mentees(id),
  rating      text DEFAULT '',
  good        text DEFAULT '',
  improve     text DEFAULT '',
  submitted_at timestamptz DEFAULT now()
);

-- ═══ 8. session_log (세션 이력) ═══
CREATE TABLE public.session_log (
  id           serial PRIMARY KEY,
  session_id   text NOT NULL,
  action       text NOT NULL,
  cancelled_by text DEFAULT '',
  cancelled_at timestamptz DEFAULT now()
);

-- ═══ 9. requests (요청/메시지) ═══
CREATE TABLE public.requests (
  id            text PRIMARY KEY,
  author_id     text DEFAULT '',
  author_name   text DEFAULT '',
  author_role   text DEFAULT '',
  type          text DEFAULT '',
  title         text DEFAULT '',
  content       text DEFAULT '',
  status        text DEFAULT '대기중',
  reply         text DEFAULT '',
  reply_read    boolean DEFAULT false,
  sender        text DEFAULT '',
  receiver_id   text DEFAULT '',
  receiver      text DEFAULT '',
  receiver_role text DEFAULT '',
  message_type  text DEFAULT '',
  created_at    timestamptz DEFAULT now()
);

-- ═══ 10. notices (공지사항) ═══
CREATE TABLE public.notices (
  id           text PRIMARY KEY,
  target       text DEFAULT '전체' CHECK (target IN ('전체','멘토만','멘티만')),
  title        text DEFAULT '',
  content      text DEFAULT '',
  is_important boolean DEFAULT false,
  is_deleted   boolean DEFAULT false,
  created_at   timestamptz DEFAULT now()
);

-- ═══ 인덱스 ═══
CREATE INDEX idx_slots_mentor    ON public.slots(mentor_id);
CREATE INDEX idx_sessions_mentor ON public.sessions(mentor_id);
CREATE INDEX idx_sessions_mentee ON public.sessions(mentee_id);
CREATE INDEX idx_sessions_status ON public.sessions(status);
CREATE INDEX idx_journals_mentor ON public.journals(mentor_id);
CREATE INDEX idx_journals_session ON public.journals(session_id);
CREATE INDEX idx_users_email     ON public.users(email);

-- ═══ 예약 동시성 제어 함수 (LockService 대체) ═══
CREATE OR REPLACE FUNCTION book_session(
  p_slot_id text,
  p_mentee_id text,
  p_topic text DEFAULT ''
) RETURNS json AS $$
DECLARE
  v_slot    record;
  v_mentor  record;
  v_sess_id text;
  v_session record;
  v_role    text := get_user_role();
  v_actor_id text := get_user_linked_id();
BEGIN
  IF v_role IS NULL OR v_role = '' THEN
    RETURN json_build_object('ok', false, 'error', '로그인 정보가 확인되지 않습니다.');
  END IF;
  IF v_role NOT IN ('admin', 'mentee') THEN
    RETURN json_build_object('ok', false, 'error', '멘티 계정만 예약할 수 있습니다.');
  END IF;
  IF v_role = 'mentee' THEN
    IF COALESCE(p_mentee_id, '') = '' THEN
      p_mentee_id := v_actor_id;
    END IF;
    IF COALESCE(p_mentee_id, '') <> COALESCE(v_actor_id, '') THEN
      RETURN json_build_object('ok', false, 'error', '본인 계정으로만 예약할 수 있습니다.');
    END IF;
  END IF;

  -- 슬롯 잠금 (FOR UPDATE = row-level lock)
  SELECT * INTO v_slot FROM public.slots WHERE id = p_slot_id FOR UPDATE;
  IF NOT FOUND THEN
    RETURN json_build_object('ok', false, 'error', '슬롯을 찾을 수 없습니다');
  END IF;
  IF v_slot.status != 'available' THEN
    RETURN json_build_object('ok', false, 'error', '이미 예약된 시간입니다');
  END IF;

  SELECT * INTO v_mentor FROM public.mentors WHERE id = v_slot.mentor_id;
  IF NOT FOUND OR v_mentor.active = false THEN
    RETURN json_build_object('ok', false, 'error', '현재 예약할 수 없는 멘토입니다');
  END IF;

  -- 같은 멘토와 이미 진행 중인 예약이 있으면 중복 방지
  IF EXISTS (
    SELECT 1 FROM public.sessions
    WHERE mentee_id = p_mentee_id
      AND mentor_id = v_slot.mentor_id
      AND status IN ('pending', 'upcoming')
  ) THEN
    RETURN json_build_object('ok', false, 'error', '해당 멘토와 이미 진행 중인 예약이 있습니다');
  END IF;

  v_sess_id := 'sess' || replace(gen_random_uuid()::text, '-', '');

  INSERT INTO public.sessions (id, mentor_id, mentee_id, slot_id, date, time, location, topic, status, has_journal, has_feedback)
  VALUES (v_sess_id, v_slot.mentor_id, p_mentee_id, p_slot_id, v_slot.date, v_slot.time, v_slot.location, p_topic, 'pending', false, false);

  UPDATE public.slots SET status = 'pending', session_id = v_sess_id WHERE id = p_slot_id;

  SELECT * INTO v_session FROM public.sessions WHERE id = v_sess_id;

  RETURN json_build_object(
    'ok', true,
    'session', json_build_object(
      'id', v_session.id, 'mentorId', v_session.mentor_id, 'menteeId', v_session.mentee_id,
      'slotId', v_session.slot_id, 'date', v_session.date, 'time', v_session.time,
      'location', v_session.location, 'topic', v_session.topic, 'status', v_session.status,
      'hasJournal', v_session.has_journal, 'hasFeedback', v_session.has_feedback
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_app_bundle()
RETURNS json AS $$
DECLARE
  v_role text := get_user_role();
  v_linked_id text := get_user_linked_id();
BEGIN
  IF v_role IS NULL OR v_role = '' THEN
    RETURN json_build_object('ok', false, 'error', 'account_not_found');
  END IF;

  IF v_role = 'admin' THEN
    RETURN json_build_object(
      'ok', true,
      'data', json_build_object(
        'mentors', COALESCE((SELECT json_agg(to_jsonb(m) ORDER BY m.created_at DESC) FROM public.mentors m), '[]'::json),
        'mentees', COALESCE((SELECT json_agg(to_jsonb(me) ORDER BY me.created_at DESC) FROM public.mentees me), '[]'::json),
        'slots', COALESCE((SELECT json_agg(to_jsonb(sl) ORDER BY sl.date, sl.time) FROM public.slots sl), '[]'::json),
        'sessions', COALESCE((SELECT json_agg(to_jsonb(s) ORDER BY s.date DESC, s.time DESC, s.created_at DESC) FROM public.sessions s), '[]'::json),
        'journals', COALESCE((SELECT json_agg(to_jsonb(j) ORDER BY j.submitted_at DESC) FROM public.journals j), '[]'::json),
        'feedbacks', COALESCE((SELECT json_agg(to_jsonb(f) ORDER BY f.submitted_at DESC) FROM public.feedbacks f), '[]'::json),
        'requests', COALESCE((SELECT json_agg(to_jsonb(r) ORDER BY r.created_at DESC) FROM public.requests r), '[]'::json),
        'notices', COALESCE((SELECT json_agg(to_jsonb(n) ORDER BY n.created_at DESC) FROM public.notices n), '[]'::json)
      )
    );
  ELSIF v_role = 'mentor' THEN
    RETURN json_build_object(
      'ok', true,
      'data', json_build_object(
        'mentors', COALESCE((SELECT json_agg(to_jsonb(m) ORDER BY m.created_at DESC) FROM public.mentors m WHERE m.id = v_linked_id AND COALESCE(m.is_deleted, false) = false), '[]'::json),
        'mentees', COALESCE((
          SELECT json_agg(to_jsonb(me) ORDER BY me.created_at DESC)
          FROM public.mentees me
          WHERE COALESCE(me.is_deleted, false) = false
            AND EXISTS (
              SELECT 1
              FROM public.sessions s
              WHERE s.mentor_id = v_linked_id
                AND s.mentee_id = me.id
            )
        ), '[]'::json),
        'slots', COALESCE((SELECT json_agg(to_jsonb(sl) ORDER BY sl.date, sl.time) FROM public.slots sl WHERE sl.mentor_id = v_linked_id AND sl.status <> 'deleted'), '[]'::json),
        'sessions', COALESCE((SELECT json_agg(to_jsonb(s) ORDER BY s.date DESC, s.time DESC, s.created_at DESC) FROM public.sessions s WHERE s.mentor_id = v_linked_id), '[]'::json),
        'journals', COALESCE((SELECT json_agg(to_jsonb(j) ORDER BY j.submitted_at DESC) FROM public.journals j WHERE j.mentor_id = v_linked_id), '[]'::json),
        'feedbacks', COALESCE((SELECT json_agg(to_jsonb(f) ORDER BY f.submitted_at DESC) FROM public.feedbacks f WHERE f.mentor_id = v_linked_id), '[]'::json),
        'requests', COALESCE((SELECT json_agg(to_jsonb(r) ORDER BY r.created_at DESC) FROM public.requests r WHERE r.author_id = v_linked_id OR r.receiver_id = v_linked_id), '[]'::json),
        'notices', COALESCE((SELECT json_agg(to_jsonb(n) ORDER BY n.created_at DESC) FROM public.notices n WHERE COALESCE(n.is_deleted, false) = false AND n.target IN ('전체', '멘토만')), '[]'::json)
      )
    );
  END IF;

  RETURN json_build_object(
    'ok', true,
    'data', json_build_object(
      'mentors', COALESCE((
        SELECT json_agg(to_jsonb(m) ORDER BY m.created_at DESC)
        FROM public.mentors m
        WHERE COALESCE(m.is_deleted, false) = false
          AND (
            COALESCE(m.active, true) = true
            OR EXISTS (
              SELECT 1
              FROM public.sessions s
              WHERE s.mentee_id = v_linked_id
                AND s.mentor_id = m.id
            )
          )
      ), '[]'::json),
      'mentees', COALESCE((SELECT json_agg(to_jsonb(me) ORDER BY me.created_at DESC) FROM public.mentees me WHERE me.id = v_linked_id AND COALESCE(me.is_deleted, false) = false), '[]'::json),
      'slots', COALESCE((
        SELECT json_agg(to_jsonb(sl) ORDER BY sl.date, sl.time)
        FROM public.slots sl
        WHERE sl.status <> 'deleted'
          AND EXISTS (
            SELECT 1
            FROM public.mentors m
            WHERE m.id = sl.mentor_id
              AND COALESCE(m.is_deleted, false) = false
              AND COALESCE(m.active, true) = true
          )
      ), '[]'::json),
      'sessions', COALESCE((SELECT json_agg(to_jsonb(s) ORDER BY s.date DESC, s.time DESC, s.created_at DESC) FROM public.sessions s WHERE s.mentee_id = v_linked_id), '[]'::json),
      'journals', '[]'::json,
      'feedbacks', COALESCE((SELECT json_agg(to_jsonb(f) ORDER BY f.submitted_at DESC) FROM public.feedbacks f WHERE f.mentee_id = v_linked_id), '[]'::json),
      'requests', COALESCE((SELECT json_agg(to_jsonb(r) ORDER BY r.created_at DESC) FROM public.requests r WHERE r.author_id = v_linked_id OR r.receiver_id = v_linked_id), '[]'::json),
      'notices', COALESCE((SELECT json_agg(to_jsonb(n) ORDER BY n.created_at DESC) FROM public.notices n WHERE COALESCE(n.is_deleted, false) = false AND n.target IN ('전체', '멘티만')), '[]'::json)
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION apply_batch_operations(p_operations jsonb)
RETURNS json AS $$
DECLARE
  op jsonb;
  v_action text;
  v_sheet text;
  v_id text;
  v_data jsonb;
  v_updates jsonb;
BEGIN
  IF p_operations IS NULL OR jsonb_typeof(p_operations) <> 'array' THEN
    RAISE EXCEPTION 'operations must be a JSON array';
  END IF;

  FOR op IN SELECT value FROM jsonb_array_elements(p_operations)
  LOOP
    v_action := COALESCE(op->>'action', '');
    v_sheet := COALESCE(op->>'sheet', '');
    v_id := COALESCE(op->>'id', '');
    v_data := COALESCE(op->'data', '{}'::jsonb);
    v_updates := COALESCE(op->'updates', '{}'::jsonb);

    IF v_action = 'append' THEN
      CASE v_sheet
        WHEN 'mentors' THEN
          INSERT INTO public.mentors (id, name, field, org, email, bio, active, is_deleted, created_at)
          VALUES (
            v_data->>'id',
            COALESCE(v_data->>'name', ''),
            COALESCE(v_data->>'field', ''),
            COALESCE(v_data->>'org', ''),
            lower(COALESCE(v_data->>'email', '')),
            COALESCE(v_data->>'bio', ''),
            COALESCE(NULLIF(v_data->>'active', '')::boolean, true),
            COALESCE(NULLIF(v_data->>'is_deleted', '')::boolean, false),
            COALESCE(NULLIF(v_data->>'created_at', '')::timestamptz, now())
          );
        WHEN 'mentees' THEN
          INSERT INTO public.mentees (id, name, team, email, is_deleted, created_at)
          VALUES (
            v_data->>'id',
            COALESCE(v_data->>'name', ''),
            COALESCE(v_data->>'team', ''),
            lower(COALESCE(v_data->>'email', '')),
            COALESCE(NULLIF(v_data->>'is_deleted', '')::boolean, false),
            COALESCE(NULLIF(v_data->>'created_at', '')::timestamptz, now())
          );
        WHEN 'journals' THEN
          INSERT INTO public.journals (id, session_id, mentor_id, mentee_id, date, type, duration, detail_location, content, issues, next_plan, rating, photo_url, submitted_at)
          VALUES (
            v_data->>'id',
            COALESCE(v_data->>'session_id', ''),
            COALESCE(v_data->>'mentor_id', ''),
            COALESCE(v_data->>'mentee_id', ''),
            COALESCE(v_data->>'date', ''),
            COALESCE(v_data->>'type', ''),
            COALESCE(v_data->>'duration', ''),
            COALESCE(v_data->>'detail_location', ''),
            COALESCE(v_data->>'content', ''),
            COALESCE(v_data->>'issues', ''),
            COALESCE(v_data->>'next_plan', COALESCE(v_data->>'next', '')),
            COALESCE(v_data->>'rating', ''),
            COALESCE(v_data->>'photo_url', ''),
            COALESCE(NULLIF(v_data->>'submitted_at', '')::timestamptz, now())
          );
        WHEN 'feedbacks' THEN
          INSERT INTO public.feedbacks (id, session_id, mentor_id, mentee_id, rating, good, improve, submitted_at)
          VALUES (
            v_data->>'id',
            COALESCE(v_data->>'session_id', ''),
            COALESCE(v_data->>'mentor_id', ''),
            COALESCE(v_data->>'mentee_id', ''),
            COALESCE(v_data->>'rating', ''),
            COALESCE(v_data->>'good', ''),
            COALESCE(v_data->>'improve', ''),
            COALESCE(NULLIF(v_data->>'submitted_at', '')::timestamptz, now())
          );
        WHEN 'sessionLog' THEN
          INSERT INTO public.session_log (session_id, action, cancelled_by, cancelled_at)
          VALUES (
            COALESCE(v_data->>'session_id', ''),
            COALESCE(v_data->>'action', ''),
            COALESCE(v_data->>'cancelled_by', ''),
            COALESCE(NULLIF(v_data->>'cancelled_at', '')::timestamptz, now())
          );
        WHEN 'requests' THEN
          INSERT INTO public.requests (id, author_id, author_name, author_role, type, title, content, status, reply, reply_read, sender, receiver_id, receiver, receiver_role, message_type, created_at)
          VALUES (
            v_data->>'id',
            COALESCE(v_data->>'author_id', ''),
            COALESCE(v_data->>'author_name', ''),
            COALESCE(v_data->>'author_role', ''),
            COALESCE(v_data->>'type', ''),
            COALESCE(v_data->>'title', ''),
            COALESCE(v_data->>'content', ''),
            COALESCE(v_data->>'status', '대기중'),
            COALESCE(v_data->>'reply', ''),
            COALESCE(NULLIF(v_data->>'reply_read', '')::boolean, false),
            COALESCE(v_data->>'sender', ''),
            COALESCE(v_data->>'receiver_id', ''),
            COALESCE(v_data->>'receiver', ''),
            COALESCE(v_data->>'receiver_role', ''),
            COALESCE(v_data->>'message_type', ''),
            COALESCE(NULLIF(v_data->>'created_at', '')::timestamptz, now())
          );
        ELSE
          RAISE EXCEPTION 'Unsupported append target: %', v_sheet;
      END CASE;
    ELSIF v_action = 'update' THEN
      CASE v_sheet
        WHEN 'mentors' THEN
          UPDATE public.mentors
          SET
            name = CASE WHEN v_updates ? 'name' THEN COALESCE(v_updates->>'name', '') ELSE name END,
            field = CASE WHEN v_updates ? 'field' THEN COALESCE(v_updates->>'field', '') ELSE field END,
            org = CASE WHEN v_updates ? 'org' THEN COALESCE(v_updates->>'org', '') ELSE org END,
            email = CASE WHEN v_updates ? 'email' THEN lower(COALESCE(v_updates->>'email', '')) ELSE email END,
            bio = CASE WHEN v_updates ? 'bio' THEN COALESCE(v_updates->>'bio', '') ELSE bio END,
            active = CASE WHEN v_updates ? 'active' THEN COALESCE(NULLIF(v_updates->>'active', '')::boolean, active) ELSE active END,
            is_deleted = CASE WHEN v_updates ? 'is_deleted' THEN COALESCE(NULLIF(v_updates->>'is_deleted', '')::boolean, is_deleted) ELSE is_deleted END
          WHERE id = v_id;
        WHEN 'mentees' THEN
          UPDATE public.mentees
          SET
            name = CASE WHEN v_updates ? 'name' THEN COALESCE(v_updates->>'name', '') ELSE name END,
            team = CASE WHEN v_updates ? 'team' THEN COALESCE(v_updates->>'team', '') ELSE team END,
            email = CASE WHEN v_updates ? 'email' THEN lower(COALESCE(v_updates->>'email', '')) ELSE email END,
            is_deleted = CASE WHEN v_updates ? 'is_deleted' THEN COALESCE(NULLIF(v_updates->>'is_deleted', '')::boolean, is_deleted) ELSE is_deleted END
          WHERE id = v_id;
        WHEN 'slots' THEN
          UPDATE public.slots
          SET
            date = CASE WHEN v_updates ? 'date' THEN COALESCE(v_updates->>'date', '') ELSE date END,
            time = CASE WHEN v_updates ? 'time' THEN COALESCE(v_updates->>'time', '') ELSE time END,
            location = CASE WHEN v_updates ? 'location' THEN COALESCE(v_updates->>'location', '') ELSE location END,
            status = CASE WHEN v_updates ? 'status' THEN COALESCE(v_updates->>'status', status) ELSE status END,
            session_id = CASE WHEN v_updates ? 'session_id' THEN COALESCE(v_updates->>'session_id', '') ELSE session_id END
          WHERE id = v_id;
        WHEN 'sessions' THEN
          UPDATE public.sessions
          SET
            status = CASE WHEN v_updates ? 'status' THEN COALESCE(v_updates->>'status', status) ELSE status END,
            topic = CASE WHEN v_updates ? 'topic' THEN COALESCE(v_updates->>'topic', '') ELSE topic END,
            location = CASE WHEN v_updates ? 'location' THEN COALESCE(v_updates->>'location', '') ELSE location END,
            has_journal = CASE WHEN v_updates ? 'has_journal' THEN COALESCE(NULLIF(v_updates->>'has_journal', '')::boolean, has_journal) ELSE has_journal END,
            has_feedback = CASE WHEN v_updates ? 'has_feedback' THEN COALESCE(NULLIF(v_updates->>'has_feedback', '')::boolean, has_feedback) ELSE has_feedback END
          WHERE id = v_id;
        WHEN 'journals' THEN
          UPDATE public.journals
          SET
            type = CASE WHEN v_updates ? 'type' THEN COALESCE(v_updates->>'type', '') ELSE type END,
            duration = CASE WHEN v_updates ? 'duration' THEN COALESCE(v_updates->>'duration', '') ELSE duration END,
            detail_location = CASE WHEN v_updates ? 'detail_location' THEN COALESCE(v_updates->>'detail_location', '') ELSE detail_location END,
            content = CASE WHEN v_updates ? 'content' THEN COALESCE(v_updates->>'content', '') ELSE content END,
            issues = CASE WHEN v_updates ? 'issues' THEN COALESCE(v_updates->>'issues', '') ELSE issues END,
            next_plan = CASE
              WHEN v_updates ? 'next_plan' THEN COALESCE(v_updates->>'next_plan', '')
              WHEN v_updates ? 'next' THEN COALESCE(v_updates->>'next', '')
              ELSE next_plan
            END,
            rating = CASE WHEN v_updates ? 'rating' THEN COALESCE(v_updates->>'rating', '') ELSE rating END,
            photo_url = CASE WHEN v_updates ? 'photo_url' THEN COALESCE(v_updates->>'photo_url', '') ELSE photo_url END,
            submitted_at = CASE WHEN v_updates ? 'submitted_at' THEN COALESCE(NULLIF(v_updates->>'submitted_at', '')::timestamptz, submitted_at) ELSE submitted_at END
          WHERE id = v_id;
        WHEN 'requests' THEN
          UPDATE public.requests
          SET
            status = CASE WHEN v_updates ? 'status' THEN COALESCE(v_updates->>'status', '') ELSE status END,
            reply = CASE WHEN v_updates ? 'reply' THEN COALESCE(v_updates->>'reply', '') ELSE reply END,
            reply_read = CASE WHEN v_updates ? 'reply_read' THEN COALESCE(NULLIF(v_updates->>'reply_read', '')::boolean, reply_read) ELSE reply_read END,
            title = CASE WHEN v_updates ? 'title' THEN COALESCE(v_updates->>'title', '') ELSE title END,
            content = CASE WHEN v_updates ? 'content' THEN COALESCE(v_updates->>'content', '') ELSE content END
          WHERE id = v_id;
        WHEN 'notices' THEN
          UPDATE public.notices
          SET
            target = CASE WHEN v_updates ? 'target' THEN COALESCE(v_updates->>'target', target) ELSE target END,
            title = CASE WHEN v_updates ? 'title' THEN COALESCE(v_updates->>'title', '') ELSE title END,
            content = CASE WHEN v_updates ? 'content' THEN COALESCE(v_updates->>'content', '') ELSE content END,
            is_important = CASE WHEN v_updates ? 'is_important' THEN COALESCE(NULLIF(v_updates->>'is_important', '')::boolean, is_important) ELSE is_important END,
            is_deleted = CASE WHEN v_updates ? 'is_deleted' THEN COALESCE(NULLIF(v_updates->>'is_deleted', '')::boolean, is_deleted) ELSE is_deleted END
          WHERE id = v_id;
        ELSE
          RAISE EXCEPTION 'Unsupported update target: %', v_sheet;
      END CASE;

      IF NOT FOUND THEN
        RAISE EXCEPTION 'Update target not found: % (%).', v_sheet, v_id;
      END IF;
    ELSIF v_action = 'upsertUser' THEN
      INSERT INTO public.users (email, role, name, linked_id, created_at)
      VALUES (
        lower(COALESCE(v_data->>'email', '')),
        COALESCE(v_data->>'role', ''),
        COALESCE(v_data->>'name', ''),
        COALESCE(v_data->>'linked_id', ''),
        now()
      )
      ON CONFLICT (email, role)
      DO UPDATE
      SET
        name = EXCLUDED.name,
        linked_id = EXCLUDED.linked_id,
        created_at = now();
    ELSE
      RAISE EXCEPTION 'Unsupported batch action: %', v_action;
    END IF;
  END LOOP;

  RETURN json_build_object('ok', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══ Realtime 활성화 ═══
ALTER PUBLICATION supabase_realtime ADD TABLE public.sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.slots;
ALTER PUBLICATION supabase_realtime ADD TABLE public.requests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notices;
ALTER PUBLICATION supabase_realtime ADD TABLE public.mentors;
ALTER PUBLICATION supabase_realtime ADD TABLE public.mentees;
ALTER PUBLICATION supabase_realtime ADD TABLE public.journals;
ALTER PUBLICATION supabase_realtime ADD TABLE public.feedbacks;

SET check_function_bodies = on;
