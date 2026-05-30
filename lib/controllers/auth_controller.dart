import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      return AuthController(repository);
    });

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.data(null));

  void reset() {
    state = const AsyncValue.data(null);
  }

  Future<void> login(String email, String password) async {
    try {
      state = const AsyncValue.loading();
      final user = await _repository.login(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> register(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      state = const AsyncValue.loading();
      await _repository.register(email, password, displayName);
      await _repository.logout(); // Sign out to force manual login
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    try {
      state = const AsyncValue.loading();
      await _repository.logout();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
