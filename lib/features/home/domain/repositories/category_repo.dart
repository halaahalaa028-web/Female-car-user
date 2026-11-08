import 'package:get/get_connect/http/src/response/response.dart';
import 'package:ride_sharing_user_app/data/api_client.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';


class CategoryRepo{
  final ApiClient apiClient;

  CategoryRepo({required this.apiClient});

  Future<Response?> getCategoryList() async {
    Response response = await apiClient.getData(AppConstants.vehicleMainCategory);
    if (response.statusCode == 200 &&
        response.body != null &&
        response.body['data'] is List &&
        (response.body['data'] as List).isEmpty) {
      final Map<String, String> headerWithoutZone = apiClient.getHeader();
      headerWithoutZone.remove('zoneId');
      response = await apiClient.getData(AppConstants.vehicleMainCategory, headers: headerWithoutZone);
    }
    return response;
  }

}