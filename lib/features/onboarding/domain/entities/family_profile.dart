class FamilyMember {
  final String name;
  final DateTime birthDate;
  final String relation; // e.g., father, mother, son, daughter, etc.

  const FamilyMember({
    required this.name,
    required this.birthDate,
    required this.relation,
  });
}

class FamilyProfile {
  final String familyName;
  final List<FamilyMember> members;

  const FamilyProfile({
    required this.familyName,
    required this.members,
  });
}