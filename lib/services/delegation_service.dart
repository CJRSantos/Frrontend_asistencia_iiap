import '../config/api_config.dart';
import '../models/delegation_model.dart';
import 'api_service.dart';

class DelegationService {
  // Create delegation
  static Future<DelegationModel> createDelegation({
    required String delegateId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await ApiService.post(
      ApiConfig.delegations,
      body: {
        'delegate_id': delegateId,
        'start_date': startDate,
        'end_date': endDate,
      },
      requiresAuth: true,
    );
    return DelegationModel.fromJson(response as Map<String, dynamic>);
  }

  // Get my delegations
  static Future<List<DelegationModel>> getMyDelegations() async {
    final response = await ApiService.get(ApiConfig.delegations, requiresAuth: true);
    if (response is List) {
      return response.map((item) => DelegationModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  // Deactivate delegation
  static Future<dynamic> deactivateDelegation(String id) async {
    return await ApiService.patch(
      ApiConfig.deactivateDelegation(id),
      requiresAuth: true,
    );
  }
}
