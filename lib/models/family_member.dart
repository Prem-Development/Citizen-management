class FamilyMember {
  final int? id;
  final String citizenNic;
  final String name;
  final String relationship;
  final String dob;
  final String gender;
  final String education;
  final String maritalStatus;
  final String occupation;
  final String nic;
  final String notes;

  const FamilyMember({
    this.id,
    required this.citizenNic,
    required this.name,
    this.relationship = '',
    this.dob = '',
    this.gender = '',
    this.education = '',
    this.maritalStatus = '',
    this.occupation = '',
    this.nic = '',
    this.notes = '',
  });

  FamilyMember copyWith({
    int? id,
    String? citizenNic,
    String? name,
    String? relationship,
    String? dob,
    String? gender,
    String? education,
    String? maritalStatus,
    String? occupation,
    String? nic,
    String? notes,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      citizenNic: citizenNic ?? this.citizenNic,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      education: education ?? this.education,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      occupation: occupation ?? this.occupation,
      nic: nic ?? this.nic,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'citizen_nic': citizenNic,
      'name': name,
      'relationship': relationship,
      'dob': dob,
      'gender': gender,
      'education': education,
      'marital_status': maritalStatus,
      'occupation': occupation,
      'nic': nic,
      'notes': notes,
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] as int?,
      citizenNic: map['citizen_nic'] as String? ?? '',
      name: map['name'] as String? ?? '',
      relationship: map['relationship'] as String? ?? '',
      dob: map['dob'] as String? ?? '',
      gender: map['gender'] as String? ?? '',
      education: map['education'] as String? ?? '',
      maritalStatus: map['marital_status'] as String? ?? '',
      occupation: map['occupation'] as String? ?? '',
      nic: map['nic'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
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
  String toString() => 'FamilyMember(id: $id, name: $name, relationship: $relationship)';
}
