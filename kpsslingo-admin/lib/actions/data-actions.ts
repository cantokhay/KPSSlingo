// lib/actions/data-actions.ts
'use server'

import { createSupabaseServerClient } from '@/lib/supabase/server'

export async function getTopics() {
  const supabase = await createSupabaseServerClient()
  const { data, error } = await supabase
    .from('topics')
    .select('id, title, slug')
    .order('title', { ascending: true })

  if (error) {
    console.error('Error fetching topics:', error)
    return []
  }
  return data
}

export async function getLessonsByTopic(topicId: string) {
  const supabase = await createSupabaseServerClient()
  const { data, error } = await supabase
    .from('lessons')
    .select('id, title, status')
    .eq('topic_id', topicId)
    .order('title', { ascending: true })

  if (error) {
    console.error('Error fetching lessons:', error)
    return []
  }
  return data
}
