
import 'dart:io';
import 'dart:typed_data';

import '../config/endpoint.dart';
import '../config/model/resp.dart';
import '../config/network.dart';
import '../config/pref.dart';
import 'package:http/http.dart' as http;

class ReportViewmodel {

  Future<Resp> stockInReports() async {
    String? token = await Session().getUserToken();

    var header = <String, dynamic>{};
    header[HttpHeaders.authorizationHeader] = 'Bearer $token';

    var resp = await Network.getApiWithHeaders(
        Endpoint.stockInReports,header);
    Resp data = Resp.fromJson(resp);
    return data;
  }

  Future<Resp> stockOutsReports() async {
    String? token = await Session().getUserToken();

    var header = <String, dynamic>{};
    header[HttpHeaders.authorizationHeader] = 'Bearer $token';

    var resp = await Network.getApiWithHeaders(
        Endpoint.stockOutsReports,header);
    Resp data = Resp.fromJson(resp);
    return data;
  }

  Future<Resp> stockOutsPDF() async {
    String? token = await Session().getUserToken();

    var header = <String, dynamic>{};
    header[HttpHeaders.authorizationHeader] = 'Bearer $token';

    var resp = await Network.getApiWithHeaders(
        Endpoint.stockOutPDF,header);
    Resp data = Resp.fromJson(resp);
    return data;
  }

  Future<Uint8List> stockInPDFBytes({DateTime? from, DateTime? to}) async {
    final token = await Session().getUserToken();

    final uri = _resolveUri(
      "https://forvideo.my.id",                // <- pastikan ada, mis. "https://api.yourdomain.com"
      Endpoint.stockInPDF,             // <- boleh "/api/reports/stock-ins/pdf" atau full URL
      query: {
        if (from != null) 'from': _fmt(from),
        if (to != null) 'to': _fmt(to),
      },
    );

    final resp = await http.get(
      uri,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.acceptHeader: 'application/pdf',
      },
    );
    if (resp.statusCode != 200) {
      throw Exception('Export PDF gagal (${resp.statusCode})');
    }
    return resp.bodyBytes;
  }

  // ====== EXPORT PDF BYTES (STOCK OUT) – opsional kembaran ======
  Future<Uint8List> stockOutPDFBytes({DateTime? from, DateTime? to}) async {
    final token = await Session().getUserToken();

    final uri = _resolveUri(
      "https://forvideo.my.id",
      Endpoint.stockOutPDF,
      query: {
        if (from != null) 'from': _fmt(from),
        if (to != null) 'to': _fmt(to),
      },
    );

    final resp = await http.get(
      uri,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.acceptHeader: 'application/pdf',
      },
    );
    if (resp.statusCode != 200) {
      throw Exception('Export PDF gagal (${resp.statusCode})');
    }
    return resp.bodyBytes;
  }

  Uri _resolveUri(String baseUrl, String pathOrUrl, {Map<String, String>? query}) {
    // baseUrl: mis. https://example.com  (PASTIKAN ada di Endpoint.baseUrl)
    // pathOrUrl: bisa relatif (/api/...) atau absolut (https://example.com/api/...)
    final initial = Uri.parse(baseUrl).resolve(pathOrUrl);
    final merged = <String, String>{
      ...initial.queryParameters,
      ...?query,
    };
    return initial.replace(queryParameters: merged.isEmpty ? null : merged);
  }

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }
}