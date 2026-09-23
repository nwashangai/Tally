import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks whether the initial animated splash sequence has completed.
/// Ensures the user experiences the full 3D orbit and progressive logo reveal
/// before navigating to the main application screens.
final splashCompletedProvider = StateProvider<bool>((ref) => false);
