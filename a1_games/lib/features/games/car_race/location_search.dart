import 'dart:convert';
import 'dart:io';

/// Free place search. No Google key. Needs internet.
class LocationSearch {
  LocationSearch._();

  static Future<({String name, double lat, double lng})?> find(String query) async {
    final q = query.trim();
    if (q.length < 2) return null;
    final client = HttpClient();
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'json',
        'limit': '1',
      });
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, 'a1_games/1.0 (route racer)');
      final res = await req.close().timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      final list = jsonDecode(body);
      if (list is! List || list.isEmpty) return null;
      final hit = list.first;
      if (hit is! Map) return null;
      final rawName = hit['display_name']?.toString() ?? q;
      final name = rawName.split(',').first.trim();
      final lat = double.tryParse(hit['lat']?.toString() ?? '');
      final lng = double.tryParse(hit['lon']?.toString() ?? '');
      if (lat == null || lng == null || name.isEmpty) return null;
      return (name: name, lat: lat, lng: lng);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
