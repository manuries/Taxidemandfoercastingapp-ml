import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://192.168.64.103:8000";

  // ✅ Predict demand using ML model (role-based)
  static Future<Map<String, dynamic>> predict(int pickupHour, int isWeekend, String role) async {
    final response = await http.post(
      Uri.parse("$baseUrl/predict"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"pickup_hour": pickupHour, "is_weekend": isWeekend, "role": role}),
    );
    return jsonDecode(response.body);
  }

  // ✅ Forecast demand using Prophet model
  static Future<List<dynamic>> forecast(int hours) async {
    final response = await http.get(Uri.parse("$baseUrl/forecast?hours=$hours"));
    return jsonDecode(response.body);
  }

  // ✅ Zone forecast with filters (zone, pickupHour, isWeekend)
  static Future<List<dynamic>> zoneForecast(
      int hours, {
        String? zone,
        int? pickupHour,
        int? isWeekend,
      }) async {
    final queryParams = {
      "hours": hours.toString(),
      if (zone != null) "zone": zone,
      if (pickupHour != null) "pickup_hour": pickupHour.toString(),
      if (isWeekend != null) "is_weekend": isWeekend.toString(),
    };

    final uri = Uri.parse("$baseUrl/zone_forecast").replace(queryParameters: queryParams);

    final response = await http.get(uri);
    print("ZoneForecast raw response: ${response.body}");
    return jsonDecode(response.body);
  }
}
