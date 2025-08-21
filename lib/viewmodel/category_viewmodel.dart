
import 'dart:io';

import '../config/endpoint.dart';
import '../config/model/resp.dart';
import '../config/network.dart';
import '../config/pref.dart';

class CategoryViewmodel {
  Future<Resp> getCategory() async {
    String? token = await Session().getUserToken();

    var header = <String, dynamic>{};
    header[HttpHeaders.authorizationHeader] = 'Bearer $token';

    var resp = await Network.getApiWithHeaders(
        Endpoint.categoriesUrl, header);
    Resp data = Resp.fromJson(resp);
    return data;
  }
}