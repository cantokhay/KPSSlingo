-- EXTENSION & HELPERS
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TABLO: user_profiles
CREATE TABLE user_profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username        TEXT UNIQUE NOT NULL,
  full_name       TEXT,
  avatar_url      TEXT,
  total_xp        INTEGER NOT NULL DEFAULT 0,
  current_level   INTEGER NOT NULL DEFAULT 1,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE TRIGGER trg_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcı kendi profilini okuyabilir"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Kullanıcı kendi profilini güncelleyebilir"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admin her şeyi okuyabilir"
  ON user_profiles FOR ALL
  USING (auth.jwt() ->> 'role' = 'admin');

-- TABLO: streaks
CREATE TABLE streaks (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  current_streak      INTEGER NOT NULL DEFAULT 0,
  longest_streak      INTEGER NOT NULL DEFAULT 0,
  last_activity_date  DATE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

CREATE TRIGGER trg_streaks_updated_at
  BEFORE UPDATE ON streaks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE streaks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcı kendi streak'ini okuyabilir"
  ON streaks FOR SELECT
  USING (auth.uid() = user_id);

-- TABLO: topics
CREATE TYPE topic_status AS ENUM ('active', 'inactive');

CREATE TABLE topics (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        TEXT UNIQUE NOT NULL,
  title       TEXT NOT NULL,
  description TEXT,
  icon_url    TEXT,
  "order"     INTEGER NOT NULL DEFAULT 0,
  status      topic_status NOT NULL DEFAULT 'active',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at  TIMESTAMPTZ
);

CREATE TRIGGER trg_topics_updated_at
  BEFORE UPDATE ON topics
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE topics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Herkes aktif konuları okuyabilir"
  ON topics FOR SELECT
  USING (status = 'active' AND deleted_at IS NULL);

-- TABLO: lessons
CREATE TYPE lesson_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE lesson_difficulty AS ENUM ('beginner', 'intermediate', 'advanced');

CREATE TABLE lessons (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id        UUID NOT NULL REFERENCES topics(id),
  title           TEXT NOT NULL,
  description     TEXT,
  "order"         INTEGER NOT NULL DEFAULT 0,
  difficulty      lesson_difficulty NOT NULL DEFAULT 'beginner',
  status          lesson_status NOT NULL DEFAULT 'draft',
  xp_reward       INTEGER NOT NULL DEFAULT 10,
  prerequisite_lesson_id UUID REFERENCES lessons(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ
);

CREATE TRIGGER trg_lessons_updated_at
  BEFORE UPDATE ON lessons
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Herkes yayınlanmış dersleri okuyabilir"
  ON lessons FOR SELECT
  USING (status = 'published' AND deleted_at IS NULL);

-- TABLO: questions
CREATE TYPE question_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE question_source AS ENUM ('ai_generated', 'manual', 'kpss_inspired');

CREATE TABLE questions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id       UUID NOT NULL REFERENCES lessons(id),
  body            TEXT NOT NULL,
  explanation     TEXT,
  correct_option  CHAR(1) NOT NULL,
  status          question_status NOT NULL DEFAULT 'draft',
  source          question_source NOT NULL DEFAULT 'ai_generated',
  ai_model        TEXT,
  ai_prompt_hash  TEXT,
  reviewed_by     UUID REFERENCES auth.users(id),
  reviewed_at     TIMESTAMPTZ,
  total_attempts  INTEGER NOT NULL DEFAULT 0,
  correct_answers INTEGER NOT NULL DEFAULT 0,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at      TIMESTAMPTZ,
  CONSTRAINT valid_correct_option CHECK (correct_option IN ('A','B','C','D','E'))
);

CREATE TRIGGER trg_questions_updated_at
  BEFORE UPDATE ON questions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_questions_lesson_id ON questions(lesson_id);
CREATE INDEX idx_questions_status ON questions(status);

ALTER TABLE questions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Herkes yayınlanmış soruları okuyabilir"
  ON questions FOR SELECT
  USING (status = 'published' AND deleted_at IS NULL);

-- TABLO: question_options
CREATE TABLE question_options (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id  UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  label        CHAR(1) NOT NULL,
  body         TEXT NOT NULL,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(question_id, label),
  CONSTRAINT valid_label CHECK (label IN ('A','B','C','D','E'))
);

ALTER TABLE question_options ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Herkes yayınlanmış sorulara ait şıkları okuyabilir"
  ON question_options FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM questions q
      WHERE q.id = question_id
      AND q.status = 'published'
      AND q.deleted_at IS NULL
    )
  );

-- TABLO: user_progress
CREATE TYPE progress_status AS ENUM ('not_started', 'in_progress', 'completed');

CREATE TABLE user_progress (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  lesson_id     UUID NOT NULL REFERENCES lessons(id),
  status        progress_status NOT NULL DEFAULT 'not_started',
  score         INTEGER,
  best_score    INTEGER,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  completed_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id, lesson_id)
);

CREATE TRIGGER trg_user_progress_updated_at
  BEFORE UPDATE ON user_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE INDEX idx_user_progress_user_id ON user_progress(user_id);

ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcı kendi ilerlemesini okuyabilir"
  ON user_progress FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcı kendi ilerlemesini güncelleyebilir"
  ON user_progress FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcı ilerleme kaydı oluşturabilir"
  ON user_progress FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- TABLO: user_question_answers
CREATE TABLE user_question_answers (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  question_id   UUID NOT NULL REFERENCES questions(id),
  lesson_id     UUID NOT NULL REFERENCES lessons(id),
  selected_option CHAR(1) NOT NULL,
  is_correct    BOOLEAN NOT NULL,
  time_spent_ms INTEGER,
  answered_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT valid_selected CHECK (selected_option IN ('A','B','C','D','E'))
);

CREATE INDEX idx_uqa_user_id ON user_question_answers(user_id);
CREATE INDEX idx_uqa_question_id ON user_question_answers(question_id);

ALTER TABLE user_question_answers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Kullanıcı kendi cevaplarını okuyabilir"
  ON user_question_answers FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Kullanıcı cevap ekleyebilir"
  ON user_question_answers FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- RPC FUNCTIONS
CREATE OR REPLACE FUNCTION add_xp_to_user(user_uuid UUID, xp_amount INTEGER)
RETURNS void AS $$
BEGIN
  UPDATE user_profiles
  SET
    total_xp = total_xp + xp_amount,
    current_level = FLOOR((total_xp + xp_amount) / 100) + 1
  WHERE id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION increment_question_stats(q_id UUID, is_correct BOOLEAN)
RETURNS void AS $$
BEGIN
  UPDATE questions
  SET
    total_attempts = total_attempts + 1,
    correct_answers = correct_answers + (CASE WHEN is_correct THEN 1 ELSE 0 END)
  WHERE id = q_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
