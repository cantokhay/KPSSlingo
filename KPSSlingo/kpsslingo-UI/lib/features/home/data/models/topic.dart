class Topic {
  final String id;
  final String slug;
  final String title;
  final String? description;
  final String? emoji;
  final String? iconUrl;
  final int order;

  const Topic({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    this.emoji,
    this.iconUrl,
    required this.order,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'] as String,
        slug: json['slug'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        emoji: json['emoji'] as String?,
        iconUrl: json['icon_url'] as String?,
        order: json['order'] as int,
      );
}
