import 'package:shared_preferences/shared_preferences.dart';
import '../models/campus_building.dart';

class FavoritesService {
  static const _key = 'favorite_building_names';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<String>> loadFavoriteNames() async {
    final p = await _prefs;
    return p.getStringList(_key) ?? <String>[];
  }

  Future<void> saveFavoriteNames(List<String> names) async {
    final p = await _prefs;
    await p.setStringList(_key, names);
  }

  Future<void> addFavorite(String buildingName) async {
    final names = await loadFavoriteNames();
    if (!names.contains(buildingName)) {
      names.add(buildingName);
      await saveFavoriteNames(names);
    }
  }

  Future<void> removeFavorite(String buildingName) async {
    final names = await loadFavoriteNames();
    names.removeWhere((n) => n == buildingName);
    await saveFavoriteNames(names);
  }

  Future<List<CampusBuilding>> loadFavorites(List<CampusBuilding> source) async {
    final names = await loadFavoriteNames();
    final lower = names.map((e) => e.toLowerCase()).toSet();
    return source.where((b) => lower.contains(b.name.toLowerCase())).toList();
  }
}
