import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/entity_id.dart';
import '../models/operations.dart';
import '../repository/repository.dart';

/// Port of `CertificationsStore` (Core/Stores/CertificationsStore.swift).
///
/// Supports two load modes: federation-wide ([loadAll]) and per-coach
/// ([loadForCoach]), matching the two Swift load methods. Derived slices
/// [expired] and [expiringSoon] are computed getters on the state.

enum CertificationsStatus { initial, loading, ready, failed }

class CertificationsState extends Equatable {
  final CertificationsStatus status;
  final List<Certification> certifications;

  const CertificationsState({
    this.status = CertificationsStatus.initial,
    this.certifications = const [],
  });

  /// Certifications whose [CertificationSeverity] is [CertificationSeverity.expired].
  /// Mirrors [CertificationsStore.expired].
  List<Certification> get expired => certifications
      .where((c) => c.severity == CertificationSeverity.expired)
      .toList();

  /// Certifications expiring within the threshold window (< 60 days by the
  /// [Certification.severity] getter). Mirrors [CertificationsStore.expiringSoon].
  List<Certification> get expiringSoon => certifications
      .where((c) => c.severity == CertificationSeverity.expiring)
      .toList();

  CertificationsState copyWith({
    CertificationsStatus? status,
    List<Certification>? certifications,
  }) => CertificationsState(
    status: status ?? this.status,
    certifications: certifications ?? this.certifications,
  );

  @override
  List<Object?> get props => [status, certifications];
}

class CertificationsCubit extends Cubit<CertificationsState> {
  final Repository _repo;

  CertificationsCubit(this._repo) : super(const CertificationsState());

  /// Loads all certifications across every coach.
  /// Mirrors [CertificationsStore.loadAll].
  Future<void> loadAll() async {
    emit(state.copyWith(status: CertificationsStatus.loading));
    try {
      final certs = await _repo.certifications();
      emit(
        state.copyWith(
          status: CertificationsStatus.ready,
          certifications: certs,
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('CertificationsCubit.loadAll: $e');
      emit(state.copyWith(status: CertificationsStatus.failed));
    }
  }

  /// Loads certifications for a specific coach.
  /// Mirrors [CertificationsStore.load(coachID:)].
  Future<void> loadForCoach(EntityID coachId) async {
    emit(state.copyWith(status: CertificationsStatus.loading));
    try {
      final certs = await _repo.certificationsForCoach(coachId);
      emit(
        state.copyWith(
          status: CertificationsStatus.ready,
          certifications: certs,
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('CertificationsCubit.loadForCoach: $e');
      emit(state.copyWith(status: CertificationsStatus.failed));
    }
  }

  /// Updates a certification with a new issue/expiry date and reloads the
  /// full list. Mirrors [CertificationsStore.renew].
  Future<void> renew(Certification cert, DateTime newExpiry) async {
    final updated = Certification(
      id: cert.id,
      coachId: cert.coachId,
      kind: cert.kind,
      issuer: cert.issuer,
      issuedAt: DateTime.now(),
      expiresAt: newExpiry,
      fileRef: cert.fileRef,
    );
    try {
      await _repo.upsertCertification(updated);
      await loadAll();
    } catch (e) {
      // ignore: avoid_print
      print('CertificationsCubit.renew: $e');
    }
  }

  /// Upserts an arbitrary [Certification] and reloads. Useful for add /
  /// edit flows that the Swift store's [CertificationsStore] did not explicitly
  /// need (the store was load + renew only, but the Dart layer exposes this
  /// for completeness).
  Future<void> save(Certification cert) async {
    try {
      await _repo.upsertCertification(cert);
      await loadAll();
    } catch (e) {
      // ignore: avoid_print
      print('CertificationsCubit.save: $e');
    }
  }
}
