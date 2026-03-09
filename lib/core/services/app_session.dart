import '../models/auth_response.dart';

class AppSession {
  static AuthResponse? _auth;

  static void setAuth(AuthResponse auth) {
    _auth = auth;
  }

  static String get userId => _auth?.userId ?? '';
  static int get roleId => _auth?.roleId ?? 0;
  static String get fullName => _auth?.fullName ?? '';

  static void clear() {
    _auth = null;
  }
}
