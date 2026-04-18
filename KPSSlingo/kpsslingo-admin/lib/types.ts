// lib/types.ts

export type QuestionStatus = 'draft' | 'published' | 'archived' | 'draft_flagged' | 'ai_rejected'
export type QuestionSource = 'ai_generated' | 'manual' | 'kpss_inspired'

export interface QuestionOption {
  id: string
  question_id: string
  label: string      // 'A' | 'B' | 'C' | 'D' | 'E'
  body: string
}

export interface Question {
  id: string
  lesson_id: string
  body: string
  explanation: string | null
  correct_option: string
  status: QuestionStatus
  source: QuestionSource
  ai_model: string | null
  total_attempts: number
  correct_answers: number
  reviewed_by: string | null
  reviewed_at: string | null
  created_at: string
  // JOIN fields
  question_options?: QuestionOption[]
  lessons?: { 
    title: string; 
    topics?: { title: string } 
  }
}

export interface Lesson {
  id: string
  topic_id: string
  title: string
  description: string | null
  order: number
  difficulty: 'beginner' | 'intermediate' | 'advanced'
  status: 'draft' | 'published' | 'archived'
  xp_reward: number
  topics?: { title: string }
}

export interface Topic {
  id: string
  slug: string
  title: string
  description: string | null
  status: 'active' | 'inactive'
  order: number
}

export interface DashboardStats {
  total_draft_questions: number
  total_published_questions: number
  total_users: number
  total_lessons: number
}
