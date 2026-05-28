class SwitchTenantRequest {
  final String token;
  final String tenantId;

  SwitchTenantRequest({required this.token, required this.tenantId});

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'tenantId': tenantId,
    };
  }
}
