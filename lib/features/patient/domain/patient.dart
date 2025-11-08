class Patient {
  final String name;
  final String email;
  final String? phone;
  final String? notes;

  const Patient({
    required this.name,
    required this.email,
    this.phone,
    this.notes,
  });

  factory Patient.fromMap(Map<String, dynamic> map) => Patient(
        name: map['name'] as String? ?? '',
        email: map['email'] as String? ?? '',
        phone: map['phone'] as String?,
        notes: map['notes'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'notes': notes,
      };

  Patient copyWith({
    String? name,
    String? email,
    String? phone,
    String? notes,
  }) {
    return Patient(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      notes: notes ?? this.notes,
    );
  }
}
