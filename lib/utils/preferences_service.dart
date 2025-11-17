import 'package:shared_preferences/shared_preferences.dart';

class PreferencesKeys {
  static const notifications = 'notifications_enabled';
  static const locationServices = 'location_services_enabled';
  static const darkMode = 'dark_mode_enabled';
  static const mapStyle = 'default_map_style';
  static const navigationMode = 'default_navigation_mode';
  static const lastTransportMode = 'last_transport_mode';
  static const recentSearches = 'recent_searches';
  static const userName = 'user_name';
  static const userLevel = 'user_level';
  static const userDepartment = 'user_department';
  static const userAvatar = 'user_avatar_base64';
}

class PreferencesService {
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> saveBool(String key, bool value) async {
    final p = await _prefs;
    await p.setBool(key, value);
  }

  Future<void> saveString(String key, String value) async {
    final p = await _prefs;
    await p.setString(key, value);
  }

  Future<void> saveStringList(String key, List<String> values) async {
    final p = await _prefs;
    await p.setStringList(key, values);
  }

  Future<bool?> getBool(String key) async {
    final p = await _prefs;
    return p.getBool(key);
  }

  Future<String?> getString(String key) async {
    final p = await _prefs;
    return p.getString(key);
  }

  Future<List<String>?> getStringList(String key) async {
    final p = await _prefs;
    return p.getStringList(key);
  }

  Future<void> saveSettings({
    bool? notifications,
    bool? locationServices,
    bool? darkMode,
    String? mapStyle,
    String? navigationMode,
    String? lastTransportMode,
  }) async {
    final p = await _prefs;
    if (notifications != null) await p.setBool(PreferencesKeys.notifications, notifications);
    if (locationServices != null) await p.setBool(PreferencesKeys.locationServices, locationServices);
    if (darkMode != null) await p.setBool(PreferencesKeys.darkMode, darkMode);
    if (mapStyle != null) await p.setString(PreferencesKeys.mapStyle, mapStyle);
    if (navigationMode != null) await p.setString(PreferencesKeys.navigationMode, navigationMode);
    if (lastTransportMode != null) await p.setString(PreferencesKeys.lastTransportMode, lastTransportMode);
  }

  Future<Map<String, dynamic>> loadSettings() async {
    final p = await _prefs;
    return {
      PreferencesKeys.notifications: p.getBool(PreferencesKeys.notifications),
      PreferencesKeys.locationServices: p.getBool(PreferencesKeys.locationServices),
      PreferencesKeys.darkMode: p.getBool(PreferencesKeys.darkMode),
      PreferencesKeys.mapStyle: p.getString(PreferencesKeys.mapStyle),
      PreferencesKeys.navigationMode: p.getString(PreferencesKeys.navigationMode),
      PreferencesKeys.lastTransportMode: p.getString(PreferencesKeys.lastTransportMode),
    };
  }

  // Recent searches helpers
  Future<void> saveRecentSearches(List<String> names) async {
    await saveStringList(PreferencesKeys.recentSearches, names);
  }

  Future<List<String>> loadRecentSearches() async {
    final list = await getStringList(PreferencesKeys.recentSearches);
    return list ?? <String>[];
  }

  // Profile data helpers
  Future<void> saveProfileData({
    String? name,
    String? level,
    String? department,
    String? avatarBase64,
  }) async {
    final p = await _prefs;
    if (name != null) await p.setString(PreferencesKeys.userName, name);
    if (level != null) await p.setString(PreferencesKeys.userLevel, level);
    if (department != null) await p.setString(PreferencesKeys.userDepartment, department);
    if (avatarBase64 != null) await p.setString(PreferencesKeys.userAvatar, avatarBase64);
  }

  Future<Map<String, String?>> loadProfileData() async {
    final p = await _prefs;
    return {
      'name': p.getString(PreferencesKeys.userName),
      'level': p.getString(PreferencesKeys.userLevel),
      'department': p.getString(PreferencesKeys.userDepartment),
      'avatar': p.getString(PreferencesKeys.userAvatar),
    };
  }
}
