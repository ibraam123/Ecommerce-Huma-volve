import 'package:bloc/bloc.dart';
import 'package:ecommerce_app_huma_volve/features/auth/login/repos/login_repo.dart';
import 'package:meta/meta.dart';

import '../../../../core/error/failures.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._loginRepo) : super(LoginInitial());
  final LoginRepo _loginRepo;

  // Method to handle user login
  Future<void> login(String email, String password) async {
    emit(LoginLoading());
    final result = await _loginRepo.login(email: email, password: password);
    result.fold(
      (failure) => emit(LoginFailure(failure: failure)),
      (success) => emit(LoginSuccess()),
    );
  }
}
