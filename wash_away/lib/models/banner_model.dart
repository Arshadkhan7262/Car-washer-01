class Banner {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String actionType;
  final String actionValue;
  final int displayOrder;

  Banner({
    required this.id,
    required this.title,
    this.subtitle = '',
    required this.imageUrl,
    this.actionType = 'none',
    this.actionValue = '',
    this.displayOrder = 0,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      imageUrl: json['image_url']?.toString() ?? '',
      actionType: json['action_type']?.toString() ?? 'none',
      actionValue: json['action_value']?.toString() ?? '',
      displayOrder: (json['display_order'] is int)
          ? json['display_order'] as int
          : int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
    );
  }
}
