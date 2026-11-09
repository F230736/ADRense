import 'package:shared_preferences/shared_preferences.dart';

abstract interface class ThemePreferenceStore {
  Future<bool?> readLightMode();
  Future<void> saveLightMode(bool light);
}

class LocalThemePreferenceStore implements ThemePreferenceStore {
  final SharedPreferencesAsync preferences=SharedPreferencesAsync();
  Future<void> _writes=Future<void>.value();
  static const key='adrense.light_mode';
  @override Future<bool?> readLightMode() async {
    await _writes;
    return preferences.getBool(key);
  }
  @override Future<void> saveLightMode(bool light){
    final write=_writes.then((_)=>preferences.setBool(key,light));
    _writes=write.then<void>((_) {},onError:(Object error,StackTrace stack){});
    return write;
  }
}
