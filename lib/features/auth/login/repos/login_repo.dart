
import 'package:ecommerce_app_huma_volve/core/network/api_client.dart';
import 'package:ecommerce_app_huma_volve/core/network/api_endpoints.dart';
import 'package:ecommerce_app_huma_volve/features/auth/login/models/login_response.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class LoginRepo {
  Future<Either<Failure, LoginResponse>> login({required String email, required String password});
}

class LoginRepoImpl implements LoginRepo {

  final ApiClient apiClient;

  const LoginRepoImpl({required this.apiClient});

  @override
  Future<Either<Failure, LoginResponse>> login({required String email, required String password}) async {

    final responce = await apiClient.post(
      ApiEndpoints.login,
      body: {
        'email': email,
        'password': password,
      },
    );

    return Right(LoginResponse.fromJson(responce));
  }
}