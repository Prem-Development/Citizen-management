class GSProfile {
  final int id;
  final String name;
  final String division;
  final String contact;
  final String? photo;
  final String language;

  const GSProfile({
    this.id = 1,
    this.name = '',
    this.division = '',
    this.contact = '',
    this.photo,
    this.language = 'en',
  });

  GSProfile copyWith({
    int? id,
    String? name,
    String? division,
    String? contact,
    String? photo,
    String? language,
  }) {
    return GSProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      division: division ?? this.division,
      contact: contact ?? this.contact,
      photo: photo ?? this.photo,
      language: language ?? this.language,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'division': division,
      'contact': contact,
      'photo': photo,
      'language': language,
    };
  }

  factory GSProfile.fromMap(Map<String, dynamic> map) {
    return GSProfile(
      id: map['id'] as int? ?? 1,
      name: map['name'] as String? ?? '',
      division: map['division'] as String? ?? '',
      contact: map['contact'] as String? ?? '',
      photo: map['photo'] as String?,
      language: map['language'] as String? ?? 'en',
    );
  }

  bool get isSetup => name.isNotEmpty && division.isNotEmpty;

  @override
  String toString() => 'GSProfile(name: $name, division: $division, lang: $language)';
}
