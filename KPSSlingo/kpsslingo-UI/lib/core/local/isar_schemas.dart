import 'package:isar/isar.dart';

part 'isar_schemas.g.dart';

@collection
class CachedTopic {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;
  late String slug;
  late String title;
  String? description;
  String? iconUrl;
  late int order;
}

@collection
class CachedLesson {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;
  @Index()
  late String topicId;
  late String title;
  String? description;
  late int order;
  late String difficulty; // Enum as String
  late int xpReward;
}

@collection
class CachedQuestion {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;
  @Index()
  late String lessonId;
  late String body;
  String? explanation;
  late String correctOption;
  late List<String> optionsLabels; // ['A', 'B', ...]
  late List<String> optionsBodies;
}
