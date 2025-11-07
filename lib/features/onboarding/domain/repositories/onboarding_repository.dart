import 'package:olpha_app/features/onboarding/domain/entities/family_profile.dart';

abstract class OnboardingRepository {
  Future<void> saveFamilyProfile(FamilyProfile profile);
  Future<FamilyProfile?> loadFamilyProfile();
}