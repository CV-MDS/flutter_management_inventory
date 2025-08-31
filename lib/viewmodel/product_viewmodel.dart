import 'dart:io';

import 'package:dio/dio.dart';

import '../config/endpoint.dart';
import '../config/model/resp.dart';
import '../config/network.dart';
import '../config/pref.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart' as dio;


class ProductViewmodel {
  /// Tambahkan dukungan query params: page, per_page, search, action
  Future<Resp> getProducts({
    int page = 1,
    int perPage = 15,
    String? search,
    String? action,
  }) async {
    final String? token = await Session().getUserToken();

    final header = <String, dynamic>{
      HttpHeaders.authorizationHeader: 'Bearer $token',
    };

    // Bangun URL + query
    final base = Uri.parse(Endpoint.productUrl);
    final qp = <String, String>{
      'page': page.toString(),
      'per_page': perPage.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (action != null && action.isNotEmpty) 'action': action,
    };
    final url = base.replace(
      queryParameters: {
        ...base.queryParameters,
        ...qp,
      },
    ).toString();

    final resp = await Network.getApiWithHeaders(url, header);
    return Resp.fromJson(resp);
  }

  Future<Resp> createProduct({
    required String name,
    required int categoryId,
    String? description,
    String? brand,
    String? size,
    String? color,
    required int stockQuantity,
    required int minStockLevel,
    File? imageFile,
  }) async {
    final String? token = await Session().getUserToken();

    final headers = <String, dynamic>{
      HttpHeaders.authorizationHeader: 'Bearer $token',
      // Tidak perlu set Content-Type; Dio akan set otomatis untuk FormData
    };

    final map = <String, dynamic>{
      'name': name,
      'category_id': categoryId.toString(),
      'description': description ?? '',
      'brand': brand ?? '',
      'size': size ?? '',
      'color': color ?? '',
      'stock_quantity': stockQuantity.toString(),
      'min_stock_level': minStockLevel.toString(),
    };

    if (imageFile != null && await imageFile.exists()) {
      map['image'] = await MultipartFile.fromFile(
        imageFile.path,
        filename: p.basename(imageFile.path),
      );
    }

    final formData = FormData.fromMap(map);

    final resp = await Network.postApiWithHeaders(
      Endpoint.productUrl,   // contoh: https://domain.com/api/products
      formData,              // <-- kirim FormData
      headers,
    );

    return Resp.fromJson(resp);
  }

  Future<Resp> updateProduct({
    required int id,
    required String name,
    required int categoryId,
    String? description,
    String? brand,
    String? size,
    String? color,
    required int stockQuantity,
    required int minStockLevel,
    File? imageFile,
  }) async {
    final token = await Session().getUserToken();

    final headers = <String, dynamic>{
      HttpHeaders.authorizationHeader: 'Bearer $token',
      HttpHeaders.contentTypeHeader: 'multipart/form-data',
    };

    // KIRIM ANGKA SEBAGAI ANGKA (bukan string)
    final form = <String, dynamic>{
      'name'            : name,
      'category_id'     : categoryId,
      'description'     : description ?? '',
      'brand'           : brand ?? '',
      'size'            : size ?? '',
      'color'           : color ?? '',
      'stock_quantity'  : stockQuantity,
      'min_stock_level' : minStockLevel,
    };

    if (imageFile != null && await imageFile.exists()) {
      form['image'] = await dio.MultipartFile.fromFile(
        imageFile.path,
        filename: p.basename(imageFile.path),
      );
    }

    final body = dio.FormData.fromMap(form);

    try {
      /// Beberapa backend (terutama stack PHP) kurang “akrab” dengan PUT + multipart.
      /// Cara paling aman: pakai POST + _method=PUT.
      body.fields.add(const MapEntry('_method', 'PUT'));

      final resp = await Network.postApiWithHeaders(
        '${Endpoint.productUrl}/$id',
        body,
        headers,
      );
      return Resp.fromJson(resp);
    } on dio.DioException catch (e) {
      final int code = e.response?.statusCode ?? 500;
      final data = e.response?.data;

      // Tarik pesan yang enak dibaca
      String msg = 'Request failed ($code)';
      if (data is Map && data['message'] is String) {
        msg = data['message'];
      }
      if (data is Map && data['errors'] is Map) {
        final errs = <String>[];
        (data['errors'] as Map).forEach((k, v) {
          if (v is List && v.isNotEmpty) errs.add(v.first.toString());
          else if (v != null) errs.add(v.toString());
        });
        if (errs.isNotEmpty) msg = errs.join('\n');
      }

      return Resp(code: code, message: msg, data: data);
    } catch (e) {
      return Resp(code: 500, message: e.toString());
    }
  }
}
