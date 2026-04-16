import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'isar_schemas.dart';

class IsarService {
  late Isar isar;

  IsarService._();
  static final instance = IsarService._();

  Future<void> init() async {
    if (kIsWeb) return; // Isar v3.1 Web support gives 'Please use Isar 2.5.0 if you need web support'

    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [CachedTopicSchema, CachedLessonSchema, CachedQuestionSchema],
      directory: dir.path,
    );
  }

  // --- TOPICS ---
  Future<void> saveTopics(List<CachedTopic> topics) async {
    if (kIsWeb) return;
    await isar.writeTxn(() async {
      await isar.cachedTopics.putAll(topics);
    });
  }

  Future<List<CachedTopic>> getAllTopics() async {
    if (kIsWeb) return [];
    return isar.cachedTopics.where().sortByOrder().findAll();
  }

  // --- LESSONS ---
  Future<void> saveLessons(List<CachedLesson> lessons) async {
    if (kIsWeb) return;
    await isar.writeTxn(() async {
      await isar.cachedLessons.putAll(lessons);
    });
  }

  Future<List<CachedLesson>> getLessonsForTopic(String topicUuid) async {
    if (kIsWeb) return [];
    return isar.cachedLessons.where().topicIdEqualTo(topicUuid).sortByOrder().findAll();
  }

  // --- QUESTIONS ---
  Future<void> saveQuestions(List<CachedQuestion> questions) async {
    if (kIsWeb) return;
    await isar.writeTxn(() async {
      await isar.cachedQuestions.putAll(questions);
    });
  }

  Future<List<CachedQuestion>> getQuestionsForLesson(String lessonUuid) async {
    if (kIsWeb) return [];
    return isar.cachedQuestions.where().lessonIdEqualTo(lessonUuid).findAll();
  }

  // --- CLEAR CACHE ---
  Future<void> clearAll() async {
    if (kIsWeb) return;
    await isar.writeTxn(() async {
      await isar.cachedTopics.clear();
      await isar.cachedLessons.clear();
      await isar.cachedQuestions.clear();
    });
  }
}
