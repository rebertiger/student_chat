import 'package:get_it/get_it.dart';
import '../../features/auth/data/models/user_model.dart';

/// Kullanıcı bilgilerini global olarak saklamak için servis
class UserService {
  UserModel? _currentUser;

  /// Giriş yapmış kullanıcıyı ayarlar
  void setCurrentUser(UserModel user) {
    _currentUser = user;
  }

  /// Mevcut kullanıcıyı döndürür
  UserModel? getCurrentUser() {
    return _currentUser;
  }

  /// Kullanıcının tam adını döndürür
  String? getCurrentUserFullName() {
    return _currentUser?.fullName;
  }

  /// Kullanıcının ID'sini döndürür
  int? getCurrentUserId() {
    return _currentUser?.userId;
  }

  /// Kullanıcı oturumunu temizler
  void clearCurrentUser() {
    _currentUser = null;
  }
}
