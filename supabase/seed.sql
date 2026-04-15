-- Ana Konular
INSERT INTO topics (slug, title, description, "order") VALUES
  ('genel-yetenek-matematik',   'Matematik',          'Temel matematik ve sayısal muhakeme',   1),
  ('genel-yetenek-turkce',      'Türkçe',             'Dil bilgisi, okuma anlama',             2),
  ('genel-kultur-tarih',        'Tarih',              'Türk ve Dünya tarihi',                  3),
  ('genel-kultur-cografya',     'Coğrafya',           'Türkiye ve Dünya coğrafyası',           4),
  ('genel-kultur-vatandaslik',  'Vatandaşlık',        'Anayasa ve hukuk temelleri',            5),
  ('genel-kultur-guncel',       'Güncel Bilgiler',    'Atatürk ilkeleri ve güncel konular',    6);

-- Matematik → İlk 3 ders (beginner)
INSERT INTO lessons (topic_id, title, "order", difficulty, status, xp_reward) VALUES
  ((SELECT id FROM topics WHERE slug='genel-yetenek-matematik'), 'Dört İşlem',        1, 'beginner', 'published', 10),
  ((SELECT id FROM topics WHERE slug='genel-yetenek-matematik'), 'Kesirler',          2, 'beginner', 'published', 10),
  ((SELECT id FROM topics WHERE slug='genel-yetenek-matematik'), 'Yüzde Hesaplama',   3, 'beginner', 'published', 10);
