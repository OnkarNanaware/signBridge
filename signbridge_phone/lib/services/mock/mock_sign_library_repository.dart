import 'package:signbridge_phone/core/models/landmark_point.dart';
import 'package:signbridge_phone/core/models/sign_entry.dart';
import 'package:signbridge_phone/services/sign_library_repository.dart';

/// In-memory mock [SignLibraryRepository] with 5 pre-seeded reference signs.
///
/// Data is not persisted between app sessions in mock mode.
class MockSignLibraryRepository implements SignLibraryRepository {
  final Map<String, SignEntry> _store = {};

  MockSignLibraryRepository() {
    _seed();
  }

  /// Seeds the store with 5 sample entries using synthetic landmark data.
  void _seed() {
    for (final String name in const ['HELLO', 'THANK YOU', 'HELP', 'YES', 'NO']) {
      _store[name] = SignEntry(
        signName: name,
        landmarkSequence: List.generate(
          10,
          (int frameIdx) => List.generate(
            21,
            (int lmIdx) => LandmarkPoint(
              x: 0.5 + frameIdx * 0.01,
              y: 0.5 + lmIdx * 0.01,
              z: 0.0,
              landmarkIndex: lmIdx,
            ),
          ),
        ),
        dateRecorded: DateTime.utc(2025, 1, 1),
      );
    }
  }

  @override
  Future<List<SignEntry>> getAllSigns() async =>
      List<SignEntry>.unmodifiable(_store.values);

  @override
  Future<SignEntry?> getSign(String signName) async => _store[signName];

  @override
  Future<List<SignEntry>> getSamplesForSign(String signName) async =>
      _store.values
          .where(
            (SignEntry e) =>
                e.signName.toUpperCase() == signName.toUpperCase(),
          )
          .toList();

  @override
  Future<void> saveSign(SignEntry entry) async =>
      _store[entry.signName] = entry;

  @override
  Future<void> deleteSign(String signName) async {
    _store.removeWhere(
      (String k, SignEntry v) =>
          v.signName.toUpperCase() == signName.toUpperCase(),
    );
  }

  @override
  Future<void> deleteSample(SignEntry entry) async {
    _store.remove(entry.signName);
  }

  @override
  Future<int> count() async => _store.length;

  @override
  Future<void> clearAll() async => _store.clear();
}
