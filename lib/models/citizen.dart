
class Citizen {
  final String nic;
  final String name;
  final String address;
  final String village;
  final String phone;
  final String gender;
  final String dob;
  final String family;
  final String notes;
  final String? photo;
  final String? createdAt;
  final Map<int, String> customValues;

  const Citizen({
    required this.nic,
    required this.name,
    this.address = '',
    this.village = '',
    this.phone = '',
    this.gender = '',
    this.dob = '',
    this.family = '',
    this.notes = '',
    this.photo,
    this.createdAt,
    this.customValues = const {},
  });

  Citizen copyWith({
    String? nic,
    String? name,
    String? address,
    String? village,
    String? phone,
    String? gender,
    String? dob,
    String? family,
    String? notes,
    String? photo,
    String? createdAt,
    Map<int, String>? customValues,
  }) {
    return Citizen(
      nic: nic ?? this.nic,
      name: name ?? this.name,
      address: address ?? this.address,
      village: village ?? this.village,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      family: family ?? this.family,
      notes: notes ?? this.notes,
      photo: photo ?? this.photo,
      createdAt: createdAt ?? this.createdAt,
      customValues: customValues ?? this.customValues,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nic': nic,
      'name': name,
      'address': address,
      'village': village,
      'phone': phone,
      'gender': gender,
      'dob': dob,
      'family': family,
      'notes': notes,
      'photo': photo,
    };
  }

  factory Citizen.fromMap(Map<String, dynamic> map) {
    return Citizen(
      nic: map['nic'] as String? ?? '',
      name: map['name'] as String? ?? '',
      address: map['address'] as String? ?? '',
      village: map['village'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      gender: map['gender'] as String? ?? '',
      dob: map['dob'] as String? ?? '',
      family: map['family'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      photo: map['photo'] as String?,
      createdAt: map['created_at'] as String?,
      customValues: const {},
    );
  }

  /// Calculate age from date of birth string (YYYY-MM-DD)
  int? get age {
    if (dob.isEmpty) return null;
    try {
      final parts = dob.split('-');
      if (parts.length < 3) return null;
      final birthDate = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Citizen && runtimeType == other.runtimeType && nic == other.nic;

  @override
  int get hashCode => nic.hashCode;

  @override
  String toString() => 'Citizen(nic: $nic, name: $name)';
}
