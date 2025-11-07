import 'package:olpha_app/features/onboarding/domain/entities/family_profile.dart';
import 'package:olpha_app/features/onboarding/domain/repositories/onboarding_repository.dart';

class SaveFamilyProfile {

    final OnboardingRepository repository;

  SaveFamilyProfile(this.repository);
 Future<void> call(FamilyProfile profile){
     // Business rules go here if needed, example:
    // - validate familyName not empty
    // - limit members count, etc.
    return repository.saveFamilyProfile(profile);
 }
  
}
