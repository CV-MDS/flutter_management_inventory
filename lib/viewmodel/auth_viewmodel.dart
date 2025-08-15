
import 'dart:io';

import 'package:flutter/material.dart';

import '../config/endpoint.dart';
import '../config/model/resp.dart';
import '../config/network.dart';
import '../config/pref.dart';

class AuthViewmodel {
  Future<Resp> login({email, password}) async {

    Map<String, dynamic> formData = {
      "email": email,
      "password": password,
    };

    var resp = await Network.postApi(Endpoint.authLoginUrl, formData);
    var data = Resp.fromJson(resp);
    return data;
  }

  Future<Resp> logout() async {
    String? token = await Session().getUserToken();

    var header = <String, dynamic>{};
    header[HttpHeaders.authorizationHeader] = 'Bearer $token';

    var resp = await Network.postApiWithHeadersWithoutData(
        Endpoint.logoutUrl,header);
    Resp data = Resp.fromJson(resp);
    return data;
  }
}