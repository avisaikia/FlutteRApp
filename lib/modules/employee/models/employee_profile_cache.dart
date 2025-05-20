class UserProfileCache {
  static Map<String, dynamic>? _cachedProfile;

  static Map<String, dynamic>? get profile => _cachedProfile;

  static void setProfile(Map<String, dynamic> profile) {
    _cachedProfile = profile;
  }

  static void clear() {
    _cachedProfile = null;
  }
}
