import 'package:signbridge_phone/core/models/sign_entry.dart';

/// Abstract CRUD repository for the local sign library stored in Hive.
///
/// The sign library holds the reference landmark sequences that the DTW
/// matcher compares live gesture windows against.
abstract class SignLibraryRepository {
  /// Returns all [SignEntry]s currently stored in the library.
  Future<List<SignEntry>> getAllSigns();

  /// Returns the [SignEntry] for the given [signName], or null if not found.
  Future<SignEntry?> getSign(String signName);

  /// Returns all recorded sample [SignEntry]s for the given [signName].
  Future<List<SignEntry>> getSamplesForSign(String signName);

  /// Saves a new sample [SignEntry] to the library.
  Future<void> saveSign(SignEntry entry);

  /// Deletes all sample entries for the given [signName].
  Future<void> deleteSign(String signName);

  /// Deletes a specific sample entry from the library.
  Future<void> deleteSample(SignEntry entry);

  /// Returns the total number of recorded sign samples in the library.
  Future<int> count();

  /// Clears all entries from the library.
  ///
  /// Use with caution — intended for development/testing only.
  Future<void> clearAll();
}
