import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/role.dart';
import '../models/user.dart';
import '../repository/repository.dart';

/// Port of `AppSession` (App/AppSession.swift) — the single global, here as a
/// Cubit provided once above the router (mirrors `@Environment(AppSession)`).
///
/// Auth: when the repository implements [AuthRepository], [signIn]/[signOut]
/// drive real sessions; an unauthenticated state surfaces the sign-in screen.
/// The offline [DemoRepository] auto-resolves a current user, so it never shows
/// sign-in unless the user explicitly signs out.

class SessionState extends Equatable {
  final bool loading;
  final User? currentUser;
  final List<User> availableUsers;

  /// True while a sign-in request is in flight.
  final bool authenticating;

  /// Last sign-in error message, or null.
  final String? authError;

  const SessionState({
    this.loading = true,
    this.currentUser,
    this.availableUsers = const [],
    this.authenticating = false,
    this.authError,
  });

  bool get isAuthenticated => currentUser != null;

  SessionState copyWith({
    bool? loading,
    User? currentUser,
    List<User>? availableUsers,
    bool? authenticating,
    String? authError,
    bool clearAuthError = false,
  }) => SessionState(
    loading: loading ?? this.loading,
    currentUser: currentUser ?? this.currentUser,
    availableUsers: availableUsers ?? this.availableUsers,
    authenticating: authenticating ?? this.authenticating,
    authError: clearAuthError ? null : (authError ?? this.authError),
  );

  @override
  List<Object?> get props =>
      [loading, currentUser?.id, availableUsers, authenticating, authError];
}

class SessionCubit extends Cubit<SessionState> {
  final Repository _repo;

  SessionCubit(this._repo) : super(const SessionState());

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final users = await _repo.availableUsers();
    final current = await _repo.currentUser();
    emit(
      SessionState(loading: false, currentUser: current, availableUsers: users),
    );
  }

  Future<void> switchTo(User user) async {
    await _repo.setCurrentUser(user.id);
    final current = await _repo.currentUser();
    emit(state.copyWith(loading: false, currentUser: current));
  }

  /// Sign in via [AuthRepository]. No-op if the backend doesn't authenticate.
  Future<void> signIn({required String email, required String password}) async {
    final repo = _repo;
    if (repo is! AuthRepository) return;
    final auth = repo as AuthRepository;
    emit(state.copyWith(authenticating: true, clearAuthError: true));
    try {
      await auth.signInWithEmail(email: email, password: password);
      final current = await _repo.currentUser();
      emit(state.copyWith(
        authenticating: false,
        currentUser: current,
        clearAuthError: true,
      ));
    } catch (e) {
      emit(state.copyWith(authenticating: false, authError: e.toString()));
    }
  }

  /// Self-registration (parent account), then auto sign-in. No-op if the
  /// backend doesn't authenticate.
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final repo = _repo;
    if (repo is! AuthRepository) return;
    final auth = repo as AuthRepository;
    emit(state.copyWith(authenticating: true, clearAuthError: true));
    try {
      await _repo.createAccount(
        email: email,
        password: password,
        fullName: fullName,
        // The sign-up form has no Arabic-name field, so fullNameAr is seeded
        // from the same value; the user sets it later from account settings
        // (a future account-edit screen).
        fullNameAr: fullName,
        role: Role.parent,
      );
      await auth.signInWithEmail(email: email, password: password);
      final current = await _repo.currentUser();
      emit(state.copyWith(
        authenticating: false,
        currentUser: current,
        clearAuthError: true,
      ));
    } catch (e) {
      emit(state.copyWith(authenticating: false, authError: e.toString()));
    }
  }

  Future<void> signOut() async {
    final repo = _repo;
    if (repo is AuthRepository) {
      await (repo as AuthRepository).signOut();
    }
    final current = await _repo.currentUser();
    // Emit a fresh state so currentUser can be cleared (copyWith can't null it).
    emit(SessionState(
      loading: false,
      currentUser: current,
      availableUsers: state.availableUsers,
    ));
  }
}
