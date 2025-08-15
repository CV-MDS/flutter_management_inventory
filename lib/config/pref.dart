import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Session {
  final storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final String uuid = "uuid";
  final String userId = "user_id";
  final String userToken = "user_token";
  final String userRefreshToken = "user_refresh_token";
  final String userFullname = "user_fullname";
  final String userEmail = "user_email";
  final String userAvatar = "user_avatar";
  final String userType = "user_type";
  final String firebaseToken = "firebase_token";
  final String langCode = "lang_code";

  Future<void> setUserToken(dynamic value) async {
    return await storage.write(key: userToken, value: value);
  }

  Future<String?> getUserToken() async {
    return await storage.read(key: userToken);
  }

  Future<void> setUserRefreshToken(dynamic value) async {
    return await storage.write(key: userRefreshToken, value: value);
  }

  Future<String?> getUserRefreshToken() async {
    return await storage.read(key: userRefreshToken);
  }

  Future<void> setUserType(dynamic value) async {
    return await storage.write(key: userType, value: value);
  }

  Future<String?> getUserType() async {
    return await storage.read(key: userType);
  }

  Future<void> setUserId(dynamic value) async {
    return await storage.write(key: userId, value: value);
  }

  Future<String?> getUserId() async {
    return await storage.read(key: userId);
  }

  Future<void> setFirebaseToken(String? value) async {
    /*final sharedPref = await SharedPreferences.getInstance();
    return sharedPref.setString(firebaseToken, value);*/
    return await storage.write(key: firebaseToken, value: value);
  }

  Future<String?> getFirebaseToken() async {
    /*final sharedPref = await SharedPreferences.getInstance();
    return sharedPref.getString(firebaseToken);*/
    return await storage.read(key: firebaseToken);
  }

  Future<void> setLanguage(String langs) async {
    return await storage.write(key: langCode, value: langs);
  }

  Future<String?> getLanguage() async {
    return await storage.read(key: langCode);
  }

  logout() async {
    await storage.delete(key: userId);
    await storage.delete(key: userToken);
    await storage.delete(key: userRefreshToken);
    await storage.delete(key: firebaseToken);
    await storage.delete(key: userType);
    await storage.delete(key: userFullname);
    await storage.delete(key: userEmail);
    await storage.delete(key: userAvatar);
  }

  clearToken() async {
    await storage.delete(key: userId);
    await storage.delete(key: userToken);
    await storage.delete(key: userRefreshToken);
  }
}
