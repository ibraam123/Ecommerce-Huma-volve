import 'package:ecommerce_app_huma_volve/features/auth/login/logic/login_cubit.dart';
import 'package:ecommerce_app_huma_volve/features/auth/login/repos/login_repo.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../network/api_client.dart';
import '../network/token_storage.dart';

final getIt = GetIt.instance;

Future<void> setup() async {

  getIt.registerLazySingleton(
      () => FlutterSecureStorage()
  );


  getIt.registerLazySingleton<ApiClient>(
        () => ApiClient(),
  );

  getIt.registerLazySingleton(
      () => LoginRepoImpl(apiClient: getIt<ApiClient>() )
  );

  getIt.registerFactory(
      () => LoginCubit(
         getIt<LoginRepoImpl>()
      )
  );

}
