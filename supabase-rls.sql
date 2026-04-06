-- Supabase Row Level Security for Mentoring Hub
-- Role resolution relies on helper functions from supabase-schema.sql.

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mentors ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mentees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedbacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.session_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_proposals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "authenticated_select" ON public.users;
DROP POLICY IF EXISTS "authenticated_select" ON public.mentors;
DROP POLICY IF EXISTS "authenticated_select" ON public.mentees;
DROP POLICY IF EXISTS "authenticated_select" ON public.slots;
DROP POLICY IF EXISTS "authenticated_select" ON public.sessions;
DROP POLICY IF EXISTS "authenticated_select" ON public.journals;
DROP POLICY IF EXISTS "authenticated_select" ON public.feedbacks;
DROP POLICY IF EXISTS "authenticated_select" ON public.session_log;
DROP POLICY IF EXISTS "authenticated_select" ON public.requests;
DROP POLICY IF EXISTS "authenticated_select" ON public.notices;

DROP POLICY IF EXISTS "users_select_self_or_admin" ON public.users;
DROP POLICY IF EXISTS "mentors_select_visible" ON public.mentors;
DROP POLICY IF EXISTS "mentees_select_visible" ON public.mentees;
DROP POLICY IF EXISTS "slots_select_visible" ON public.slots;
DROP POLICY IF EXISTS "sessions_select_visible" ON public.sessions;
DROP POLICY IF EXISTS "journals_select_visible" ON public.journals;
DROP POLICY IF EXISTS "feedbacks_select_visible" ON public.feedbacks;
DROP POLICY IF EXISTS "session_log_select_visible" ON public.session_log;
DROP POLICY IF EXISTS "requests_select_visible" ON public.requests;
DROP POLICY IF EXISTS "notices_select_visible" ON public.notices;
DROP POLICY IF EXISTS "match_requests_select_visible" ON public.match_requests;
DROP POLICY IF EXISTS "match_proposals_select_visible" ON public.match_proposals;

DROP POLICY IF EXISTS "admin_insert_users" ON public.users;
DROP POLICY IF EXISTS "admin_update_users" ON public.users;
DROP POLICY IF EXISTS "admin_manage_mentors" ON public.mentors;
DROP POLICY IF EXISTS "admin_update_mentors" ON public.mentors;
DROP POLICY IF EXISTS "admin_manage_mentees" ON public.mentees;
DROP POLICY IF EXISTS "admin_update_mentees" ON public.mentees;
DROP POLICY IF EXISTS "mentor_insert_slots" ON public.slots;
DROP POLICY IF EXISTS "mentor_update_slots" ON public.slots;
DROP POLICY IF EXISTS "mentee_insert_sessions" ON public.sessions;
DROP POLICY IF EXISTS "owner_update_sessions" ON public.sessions;
DROP POLICY IF EXISTS "mentor_manage_journals" ON public.journals;
DROP POLICY IF EXISTS "mentor_update_journals" ON public.journals;
DROP POLICY IF EXISTS "mentee_manage_feedbacks" ON public.feedbacks;
DROP POLICY IF EXISTS "auth_insert_session_log" ON public.session_log;
DROP POLICY IF EXISTS "auth_insert_requests" ON public.requests;
DROP POLICY IF EXISTS "owner_update_requests" ON public.requests;
DROP POLICY IF EXISTS "admin_manage_notices" ON public.notices;
DROP POLICY IF EXISTS "admin_update_notices" ON public.notices;
DROP POLICY IF EXISTS "mentee_insert_match_requests" ON public.match_requests;
DROP POLICY IF EXISTS "owner_update_match_requests" ON public.match_requests;
DROP POLICY IF EXISTS "admin_insert_match_proposals" ON public.match_proposals;
DROP POLICY IF EXISTS "owner_update_match_proposals" ON public.match_proposals;

CREATE POLICY "users_select_self_or_admin" ON public.users
  FOR SELECT TO authenticated
  USING (
    get_user_role() = 'admin'
    OR lower(email) = get_user_email()
  );

CREATE POLICY "mentors_select_visible" ON public.mentors
  FOR SELECT TO authenticated
  USING (
    get_user_role() = 'admin'
    OR id = get_user_linked_id()
    OR (
      get_user_role() = 'mentee'
      AND COALESCE(is_deleted, false) = false
      AND (
        EXISTS (
          SELECT 1
          FROM public.match_proposals mp
          WHERE mp.mentor_id = mentors.id
            AND mp.mentee_id = get_user_linked_id()
            AND mp.status = '확정'
        )
        OR EXISTS (
          SELECT 1
          FROM public.sessions s
          WHERE s.mentor_id = mentors.id
            AND s.mentee_id = get_user_linked_id()
        )
      )
    )
  );

CREATE POLICY "mentees_select_visible" ON public.mentees
  FOR SELECT TO authenticated
  USING (
    get_user_role() = 'admin'
    OR id = get_user_linked_id()
    OR (
      get_user_role() = 'mentor'
      AND EXISTS (
        SELECT 1
        FROM public.sessions s
        WHERE s.mentor_id = get_user_linked_id()
          AND s.mentee_id = mentees.id
      )
    )
  );

CREATE POLICY "slots_select_visible" ON public.slots
  FOR SELECT TO authenticated
  USING (
    get_user_role() = 'admin'
    OR mentor_id = get_user_linked_id()
    OR (
      get_user_role() = 'mentee'
      AND status <> 'deleted'
      AND EXISTS (
        SELECT 1
        FROM public.match_proposals mp
        JOIN public.mentors m ON m.id = mp.mentor_id
        WHERE mp.mentee_id = get_user_linked_id()
          AND mp.mentor_id = slots.mentor_id
          AND mp.status = '확정'
          AND COALESCE(m.is_deleted, false) = false
          AND COALESCE(m.active, true) = true
      )
    )
  );

CREATE POLICY "sessions_select_visible" ON public.sessions
  FOR SELECT TO authenticated
  USING (
    get_user_role() = 'admin'
    OR mentor_id = get_user_linked_id()
    OR mentee_id = get_user_linked_id()
  );

CREATE POLICY "journals_select_visible" ON public.journals
  FOR SELECT TO authenticated
  USING (
    get_user_role() = 'admin'
    OR mentor_id = get_user_linked_id()
  );

CREATE POLICY "feedbacks_select_visible" ON public.feedbacks
  FOR SELECT TO authenticated
  USING (
    get_user_role() = 'admin'
    OR mentor_id = get_user_linked_id()
    OR mentee_id = get_user_linked_id()
  );

CREATE POLICY "session_log_select_visible" ON public.session_log
  FOR SELECT TO authenticated
  USING (get_user_role() = 'admin');

CREATE POLICY "requests_select_visible" ON public.requests
  FOR SELECT TO authenticated
  USING (
    get_user_role() = 'admin'
    OR author_id = get_user_linked_id()
    OR receiver_id = get_user_linked_id()
  );

CREATE POLICY "notices_select_visible" ON public.notices
  FOR SELECT TO authenticated
  USING (
    get_user_role() = 'admin'
    OR (
      COALESCE(is_deleted, false) = false
      AND (
        target = '전체'
        OR (get_user_role() = 'mentor' AND target = '멘토만')
        OR (get_user_role() = 'mentee' AND target = '멘티만')
      )
    )
  );

CREATE POLICY "match_requests_select_visible" ON public.match_requests
  FOR SELECT TO authenticated
  USING (
    get_user_role() = 'admin'
    OR mentee_id = get_user_linked_id()
    OR (
      get_user_role() = 'mentor'
      AND EXISTS (
        SELECT 1
        FROM public.match_proposals mp
        WHERE mp.request_id = match_requests.id
          AND mp.mentor_id = get_user_linked_id()
      )
    )
  );

CREATE POLICY "match_proposals_select_visible" ON public.match_proposals
  FOR SELECT TO authenticated
  USING (
    get_user_role() = 'admin'
    OR mentor_id = get_user_linked_id()
    OR mentee_id = get_user_linked_id()
  );

CREATE POLICY "admin_insert_users" ON public.users
  FOR INSERT TO authenticated
  WITH CHECK (get_user_role() = 'admin');

CREATE POLICY "admin_update_users" ON public.users
  FOR UPDATE TO authenticated
  USING (get_user_role() = 'admin');

CREATE POLICY "admin_manage_mentors" ON public.mentors
  FOR INSERT TO authenticated
  WITH CHECK (get_user_role() = 'admin');

CREATE POLICY "admin_update_mentors" ON public.mentors
  FOR UPDATE TO authenticated
  USING (get_user_role() = 'admin');

CREATE POLICY "admin_manage_mentees" ON public.mentees
  FOR INSERT TO authenticated
  WITH CHECK (get_user_role() = 'admin');

CREATE POLICY "admin_update_mentees" ON public.mentees
  FOR UPDATE TO authenticated
  USING (get_user_role() = 'admin');

CREATE POLICY "mentor_insert_slots" ON public.slots
  FOR INSERT TO authenticated
  WITH CHECK (
    get_user_role() = 'admin'
    OR (get_user_role() = 'mentor' AND mentor_id = get_user_linked_id())
  );

CREATE POLICY "mentor_update_slots" ON public.slots
  FOR UPDATE TO authenticated
  USING (
    get_user_role() = 'admin'
    OR (get_user_role() = 'mentor' AND mentor_id = get_user_linked_id())
  );

CREATE POLICY "mentee_insert_sessions" ON public.sessions
  FOR INSERT TO authenticated
  WITH CHECK (
    get_user_role() = 'admin'
    OR (get_user_role() = 'mentee' AND mentee_id = get_user_linked_id())
  );

CREATE POLICY "owner_update_sessions" ON public.sessions
  FOR UPDATE TO authenticated
  USING (
    get_user_role() = 'admin'
    OR (get_user_role() = 'mentor' AND mentor_id = get_user_linked_id())
    OR (get_user_role() = 'mentee' AND mentee_id = get_user_linked_id())
  );

CREATE POLICY "mentor_manage_journals" ON public.journals
  FOR INSERT TO authenticated
  WITH CHECK (
    get_user_role() = 'admin'
    OR (get_user_role() = 'mentor' AND mentor_id = get_user_linked_id())
  );

CREATE POLICY "mentor_update_journals" ON public.journals
  FOR UPDATE TO authenticated
  USING (
    get_user_role() = 'admin'
    OR (get_user_role() = 'mentor' AND mentor_id = get_user_linked_id())
  );

CREATE POLICY "mentee_manage_feedbacks" ON public.feedbacks
  FOR INSERT TO authenticated
  WITH CHECK (
    get_user_role() = 'admin'
    OR (get_user_role() = 'mentee' AND mentee_id = get_user_linked_id())
  );

CREATE POLICY "auth_insert_session_log" ON public.session_log
  FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "auth_insert_requests" ON public.requests
  FOR INSERT TO authenticated
  WITH CHECK (
    get_user_role() = 'admin'
    OR (
      author_role = get_user_role()
      AND author_id = get_user_linked_id()
    )
  );

CREATE POLICY "owner_update_requests" ON public.requests
  FOR UPDATE TO authenticated
  USING (
    get_user_role() = 'admin'
    OR author_id = get_user_linked_id()
    OR receiver_id = get_user_linked_id()
  );

CREATE POLICY "mentee_insert_match_requests" ON public.match_requests
  FOR INSERT TO authenticated
  WITH CHECK (
    get_user_role() = 'admin'
    OR (get_user_role() = 'mentee' AND mentee_id = get_user_linked_id())
  );

CREATE POLICY "owner_update_match_requests" ON public.match_requests
  FOR UPDATE TO authenticated
  USING (
    get_user_role() = 'admin'
    OR mentee_id = get_user_linked_id()
  );

CREATE POLICY "admin_insert_match_proposals" ON public.match_proposals
  FOR INSERT TO authenticated
  WITH CHECK (get_user_role() = 'admin');

CREATE POLICY "owner_update_match_proposals" ON public.match_proposals
  FOR UPDATE TO authenticated
  USING (
    get_user_role() = 'admin'
    OR (get_user_role() = 'mentor' AND mentor_id = get_user_linked_id())
  );

CREATE POLICY "admin_manage_notices" ON public.notices
  FOR INSERT TO authenticated
  WITH CHECK (get_user_role() = 'admin');

CREATE POLICY "admin_update_notices" ON public.notices
  FOR UPDATE TO authenticated
  USING (get_user_role() = 'admin');

REVOKE INSERT, UPDATE, DELETE ON TABLE public.users FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.mentors FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.mentees FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.slots FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.sessions FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.journals FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.feedbacks FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.session_log FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.requests FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.notices FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.match_requests FROM authenticated;
REVOKE INSERT, UPDATE, DELETE ON TABLE public.match_proposals FROM authenticated;
REVOKE ALL ON TABLE public.email_queue FROM authenticated;
REVOKE ALL ON TABLE public.email_queue FROM anon;

GRANT SELECT ON TABLE public.users TO authenticated;
GRANT SELECT ON TABLE public.mentors TO authenticated;
GRANT SELECT ON TABLE public.mentees TO authenticated;
GRANT SELECT ON TABLE public.slots TO authenticated;
GRANT SELECT ON TABLE public.sessions TO authenticated;
GRANT SELECT ON TABLE public.journals TO authenticated;
GRANT SELECT ON TABLE public.feedbacks TO authenticated;
GRANT SELECT ON TABLE public.session_log TO authenticated;
GRANT SELECT ON TABLE public.requests TO authenticated;
GRANT SELECT ON TABLE public.notices TO authenticated;
GRANT SELECT ON TABLE public.match_requests TO authenticated;
GRANT SELECT ON TABLE public.match_proposals TO authenticated;

INSERT INTO storage.buckets (id, name, public)
VALUES ('journal-photos', 'journal-photos', false)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;

DROP POLICY IF EXISTS "mentor_upload_photos" ON storage.objects;
DROP POLICY IF EXISTS "authenticated_read_photos" ON storage.objects;
DROP POLICY IF EXISTS "public_read_photos" ON storage.objects;

CREATE POLICY "mentor_upload_photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'journal-photos'
  AND get_user_role() IN ('mentor', 'admin')
);

CREATE POLICY "authenticated_read_photos"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'journal-photos'
  AND get_user_role() IN ('mentor', 'admin')
);
