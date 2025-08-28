// category_viewmodel.dart
import 'dart:io';

import '../config/endpoint.dart';
import '../config/model/resp.dart';
import '../config/network.dart';
import '../config/pref.dart';

class CategoryViewmodel {
  Future<Resp> getCategory({String? search, int? page, int? perPage}) async {
    final token = await Session().getUserToken();
    final headers = {HttpHeaders.authorizationHeader: 'Bearer $token'};

    // kalau backendmu support query ?search=&page=&per_page=
    final qs = <String, String>{};
    if ((search ?? '').isNotEmpty) qs['search'] = search!;
    if (page != null) qs['page'] = '$page';
    if (perPage != null) qs['per_page'] = '$perPage';

    final url = qs.isEmpty
        ? Endpoint.categoriesUrl
        : '${Endpoint.categoriesUrl}?${qs.entries.map((e)=>'${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';

    final resp = await Network.getApiWithHeaders(url, headers);
    return Resp.fromJson(resp);
  }

  Future<Resp> categoryDetail({required dynamic id}) async {
    final token = await Session().getUserToken();
    final headers = {HttpHeaders.authorizationHeader: 'Bearer $token'};
    final resp = await Network.getApiWithHeaders("${Endpoint.categoriesUrl}/$id", headers);
    return Resp.fromJson(resp);
  }

  Future<Resp> createCategory({required String name, String? description}) async {
    final token = await Session().getUserToken();
    final headers = {HttpHeaders.authorizationHeader: 'Bearer $token'};
    final body = {"name": name, "description": description};
    final resp = await Network.postApiWithHeaders(Endpoint.categoriesUrl, body, headers);
    return Resp.fromJson(resp);
  }

  Future<Resp> updateCategory({required dynamic id, required String name, String? description}) async {
    final token = await Session().getUserToken();
    final headers = {HttpHeaders.authorizationHeader: 'Bearer $token'};
    final body = {"name": name, "description": description};
    final resp = await Network.putApiWithHeaders("${Endpoint.categoriesUrl}/$id", body, headers);
    return Resp.fromJson(resp);
  }

  // ✅ FIX: delete by id, bukan ke /categories tanpa id
  Future<Resp> deleteCategoryById({required dynamic id}) async {
    final token = await Session().getUserToken();
    final headers = {HttpHeaders.authorizationHeader: 'Bearer $token'};
    final resp = await Network.deleteApiWithHeaders("${Endpoint.categoriesUrl}/$id", headers);
    return Resp.fromJson(resp);
  }
}
