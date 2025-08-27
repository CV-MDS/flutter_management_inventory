

import 'dart:io';

import '../config/endpoint.dart';
import '../config/model/resp.dart';
import '../config/network.dart';
import '../config/pref.dart';

class StockInViewmodel{

  Future<Resp> getHistoryStockIn({
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
    final base = Uri.parse(Endpoint.stockInHistoryUrl);
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

  Future<Resp> createStockIn({
    required String referenceNumber,
    required DateTime date,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final String? token = await Session().getUserToken();

    // Header JSON
    final headers = <String, dynamic>{
      HttpHeaders.authorizationHeader: 'Bearer $token',
      HttpHeaders.contentTypeHeader: 'application/json',
    };

    // Format tanggal: yyyy-MM-dd
    String _fmt(DateTime d) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final dd = d.day.toString().padLeft(2, '0');
      return '$y-$m-$dd';
    }

    // Bersihkan items menjadi int yang valid
    final cleanItems = items.map((e) {
      int toInt(v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
      return {
        'product_id': toInt(e['product_id']),
        'quantity': toInt(e['quantity']),
      };
    }).toList();

    final body = <String, dynamic>{
      'reference_number': referenceNumber,
      'date': _fmt(date),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'items': cleanItems,
    };

    final resp = await Network.postApiWithHeaders(
      Endpoint.stockInUrl, // contoh: https://domain.com/api/stock-ins
      body,                // JSON map
      headers,
    );

    return Resp.fromJson(resp);
  }

  Future<Resp> createStockOut({
    required String referenceNumber,
    required DateTime date,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final String? token = await Session().getUserToken();

    // Header JSON
    final headers = <String, dynamic>{
      HttpHeaders.authorizationHeader: 'Bearer $token',
      HttpHeaders.contentTypeHeader: 'application/json',
    };

    // Format tanggal: yyyy-MM-dd
    String _fmt(DateTime d) {
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final dd = d.day.toString().padLeft(2, '0');
      return '$y-$m-$dd';
    }

    // Bersihkan items menjadi int yang valid
    final cleanItems = items.map((e) {
      int toInt(v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
      return {
        'product_id': toInt(e['product_id']),
        'quantity': toInt(e['quantity']),
      };
    }).toList();

    final body = <String, dynamic>{
      'reference_number': referenceNumber,
      'date': _fmt(date),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'items': cleanItems,
    };

    final resp = await Network.postApiWithHeaders(
      Endpoint.stockOutUrl, // contoh: https://domain.com/api/stock-ins
      body,                // JSON map
      headers,
    );

    return Resp.fromJson(resp);
  }

  Future<Resp> getHistoryStockOut({
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
    final base = Uri.parse(Endpoint.stockOutUrl);
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
}