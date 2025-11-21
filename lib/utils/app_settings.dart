import 'package:flutter/foundation.dart';

class AppSettings {
  // Live settings for UI reaction
  static final ValueNotifier<bool> darkMode = ValueNotifier<bool>(false);
  static final ValueNotifier<bool> locationServices = ValueNotifier<bool>(true);
  static final ValueNotifier<bool> notifications = ValueNotifier<bool>(true);
  // mapStyle: 'standard' | 'satellite' | 'terrain'
  static final ValueNotifier<String> mapStyle = ValueNotifier<String>('standard');
  // navigationMode: 'walking' | 'driving' | 'transit'
  static final ValueNotifier<String> navigationMode = ValueNotifier<String>('walking');
}

