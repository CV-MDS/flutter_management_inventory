import 'dart:io';

import '../config/endpoint.dart';
import '../config/model/resp.dart';
import '../config/network.dart';
import '../config/pref.dart';

class ActivityViewmodel {
  /// Tambahkan dukungan query params: page, per_page, search, action
  Future<Resp> getActivities({
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
    final base = Uri.parse(Endpoint.activityRoleAdmin);
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
