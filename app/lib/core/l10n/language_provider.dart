import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/household/data/repositories/household_repository.dart';

/// Provides the current household language for localization.
/// Returns 'en' as default if no household or no user.
final languageProvider = FutureProvider<String>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return 'en';
  final household = await ref.read(householdRepositoryProvider).getHouseholdByUserId(userId);
  return household?.language ?? 'en';
});
