import '../../domain/entities/client.dart';

/// Client model for JSON serialization
class ClientModel extends Client {
  const ClientModel({
    required super.id,
    required super.email,
    super.firstName,
    super.lastName,
    super.phone,
    super.company,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) => ClientModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
      company: json['company'] as String?,
    );

  Map<String, dynamic> toJson() => {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'company': company,
    };
}

/// Auth response model
class ClientAuthResponseModel {
  const ClientAuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.client,
  });

  factory ClientAuthResponseModel.fromJson(Map<String, dynamic> json) => ClientAuthResponseModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      client: ClientModel.fromJson(json['client'] as Map<String, dynamic>),
    );

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final ClientModel client;
}
