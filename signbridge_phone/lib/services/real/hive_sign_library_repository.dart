import 'package:hive/hive.dart';
import 'package:signbridge_phone/core/constants/app_constants.dart';
import 'package:signbridge_phone/core/models/sign_entry.dart';
import 'package:signbridge_phone/services/sign_library_repository.dart';

/// Real [SignLibraryRepository] backed by a persistent local Hive box.
///
/// Stores reference sign landmark sequences captured on-device. Supports
/// multiple reference samples per sign for robust DTW matching.
class HiveSignLibraryRepository implements SignLibraryRepository {
  HiveSignLibraryRepository() : _box = Hive.box<SignEntry>(kSignLibraryBox);

  final Box<SignEntry> _box;

  @override
  Future<List<SignEntry>> getAllSigns() async => _box.values.toList();

  @override
  Future<SignEntry?> getSign(String signName) async {
    for (final SignEntry entry in _box.values) {
      if (entry.signName.toUpperCase() == signName.toUpperCase()) {
        return entry;
      }
    }
    return null;
  }

  @override
  Future<List<SignEntry>> getSamplesForSign(String signName) async =>
      _box.values
          .where(
            (SignEntry e) =>
                e.signName.toUpperCase() == signName.toUpperCase(),
          )
          .toList();

  @override
  Future<void> saveSign(SignEntry entry) async {
    await _box.add(entry);
  }

  @override
  Future<void> deleteSign(String signName) async {
    final List<dynamic> keysToDelete = [];
    for (final dynamic key in _box.keys) {
      final SignEntry? entry = _box.get(key);
      if (entry != null &&
          entry.signName.toUpperCase() == signName.toUpperCase()) {
        keysToDelete.add(key);
      }
    }
    await _box.deleteAll(keysToDelete);
  }

  @override
  Future<void> deleteSample(SignEntry entry) async {
    if (entry.isInBox) {
      await entry.delete();
    } else {
      // Find matching entry by date and name
      for (final dynamic key in _box.keys) {
        final SignEntry? stored = _box.get(key);
        if (stored != null &&
            stored.signName == entry.signName &&
            stored.dateRecorded == entry.dateRecorded) {
          await _box.delete(key);
          break;
        }
      }
    }
  }

  @override
  Future<int> count() async => _box.length;

  @override
  Future<void> clearAll() async => _box.clear();
}
