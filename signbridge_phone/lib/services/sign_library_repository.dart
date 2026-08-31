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

  /// Saves a new or updated [SignEntry] to the library.
  ///
  /// If an entry with the same [signName] already exists it will be replaced.
  Future<void> saveSign(SignEntry entry);

  /// Deletes the [SignEntry] for the given [signName].
  ///
  /// No-op if the sign does not exist.
  Future<void> deleteSign(String signName);

  /// Returns the number of signs in the library.
  Future<int> count();

  /// Clears all entries from the library.
  ///
  /// Use with caution — intended for development/testing only.
  Future<void> clearAll();
}
