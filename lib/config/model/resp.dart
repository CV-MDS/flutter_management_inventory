// lib/config/model/resp.dart

class Resp {
  int? code;
  int? statusCode; // Beberapa API mungkin menggunakan statusCode HTTP
  dynamic error;
  String? status;
  dynamic statusMsg;
  dynamic errorData;
  dynamic success; // Field boolean untuk menandakan sukses/gagal
  dynamic
  data; // Data yang sebenarnya dari API (bisa List, Map, atau tipe lain)
  dynamic message; // Pesan dari API (misalnya "Success", "User already exists")
  dynamic token;
  dynamic user;
  dynamic en; // Mungkin untuk localization?
  dynamic hk; // Mungkin untuk localization?

  Resp({
    this.error,
    this.code,
    this.statusCode,
    this.status,
    this.statusMsg,
    this.errorData,
    this.data,
    this.success,
    this.message,
    this.token,
    this.user,
    this.en,
    this.hk,
  });

  factory Resp.fromJson(Map<String, dynamic> json) {
    return Resp(
      code: json["code"] as int?,
      statusCode: json["statusCode"] as int?,
      error: json["error"],
      status: json["status"] as String?,
      statusMsg: json["statusMsg"],
      errorData: json["errorData"],
      success: json["success"],
      data: json["data"],
      message: json["message"],
      token: json["token"],
      user: json["user"],
      en: json["en"],
      hk: json["hk"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "code": code,
      "statusCode": statusCode,
      "error": error,
      "status": status,
      "statusMsg": statusMsg,
      "errorData": errorData,
      "success": success,
      "data": data,
      "message": message,
      "token": token,
      "user": user,
      "en": en,
      "hk": hk,
    };
  }
}
