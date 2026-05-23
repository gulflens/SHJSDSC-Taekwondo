import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/athlete.dart';
import '../models/belt.dart';
import '../models/branch.dart';
import '../models/entity_id.dart';
import '../models/grading.dart';
import '../repository/repository.dart';

/// Port of `GradingStore` (Core/Stores/GradingStore.swift).
///
/// Manages grading sessions for one or more branches. The [scoresBySession]
/// map is nested inside the state — a flat immutable copy updated each time
/// scores are saved. [activeSessionId] tracks the currently-focused session
/// for the examiner UI.

enum GradingStatus { initial, loading, ready, failed }

class GradingState extends Equatable {
  final GradingStatus status;
  final List<GradingSession> sessions;
  final EntityID? activeSessionId;
  final Map<EntityID, List<GradingScore>> scoresBySession;

  const GradingState({
    this.status = GradingStatus.initial,
    this.sessions = const [],
    this.activeSessionId,
    this.scoresBySession = const {},
  });

  /// Swift: `progress(for:) -> (scored: Int, total: Int)`.
  /// Returns the number of athletes scored vs. total candidates in a session.
  ({int scored, int total}) progress(EntityID sessionId) {
    final scored = scoresBySession[sessionId]?.length ?? 0;
    final total =
        sessions
            .cast<GradingSession?>()
            .firstWhere((s) => s?.id == sessionId, orElse: () => null)
            ?.candidateAthleteIds
            .length ??
        0;
    return (scored: scored, total: total);
  }

  GradingState copyWith({
    GradingStatus? status,
    List<GradingSession>? sessions,
    // Use a sentinel to allow explicitly setting activeSessionId to null.
    Object? activeSessionId = _keep,
    Map<EntityID, List<GradingScore>>? scoresBySession,
  }) => GradingState(
    status: status ?? this.status,
    sessions: sessions ?? this.sessions,
    activeSessionId: identical(activeSessionId, _keep)
        ? this.activeSessionId
        : activeSessionId as EntityID?,
    scoresBySession: scoresBySession ?? this.scoresBySession,
  );

  @override
  List<Object?> get props => [
    status,
    sessions,
    activeSessionId,
    scoresBySession,
  ];
}

// Sentinel value that distinguishes "not passed" from "explicitly set to null"
// in copyWith — needed for nullable [activeSessionId].
const Object _keep = Object();

class GradingCubit extends Cubit<GradingState> {
  final Repository _repo;

  GradingCubit(this._repo) : super(const GradingState());

  // ─────────────────────────── load ───────────────────────────────────────────

  /// Swift: `load(branchID:)`. Fetches sessions for a single branch and
  /// prefetches all scores. Maps to [Repository.gradingSessionsForBranch].
  Future<void> load(EntityID branchId) async {
    emit(state.copyWith(status: GradingStatus.loading));
    try {
      final sessions = await _repo.gradingSessionsForBranch(branchId);
      final scoresBySession = await _fetchScores(sessions);
      emit(
        state.copyWith(
          status: GradingStatus.ready,
          sessions: sessions,
          scoresBySession: scoresBySession,
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('GradingCubit.load: $e');
      emit(state.copyWith(status: GradingStatus.failed));
    }
  }

  /// Swift: `loadAll(branches:)`. Fetches sessions across multiple branches,
  /// sorted ascending by scheduled date. Maps to
  /// [Repository.gradingSessionsForBranch] called once per branch.
  Future<void> loadAll(List<Branch> branches) async {
    emit(state.copyWith(status: GradingStatus.loading));
    try {
      final all = <GradingSession>[];
      for (final b in branches) {
        all.addAll(await _repo.gradingSessionsForBranch(b.id));
      }
      all.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      final scoresBySession = await _fetchScores(all);
      emit(
        state.copyWith(
          status: GradingStatus.ready,
          sessions: all,
          scoresBySession: scoresBySession,
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('GradingCubit.loadAll: $e');
      emit(state.copyWith(status: GradingStatus.failed));
    }
  }

  // ─────────────────────── active session ─────────────────────────────────────

  /// Swift: `setActive(_ sessionID:)`. Updates [GradingState.activeSessionId].
  /// Pass null to clear the selection.
  void setActive(EntityID? sessionId) {
    emit(state.copyWith(activeSessionId: sessionId));
  }

  // ─────────────────────────── eligibility ────────────────────────────────────

  /// Swift: `eligibility(athlete:targetBelt:) async -> GradingEligibility?`.
  /// Delegates to [Repository.eligibility] (disambiguated Dart name).
  /// Returns null on error — the view can treat null as "unavailable".
  Future<GradingEligibility?> eligibility(
    Athlete athlete,
    Belt targetBelt,
  ) async {
    try {
      return await _repo.eligibility(athlete.id, targetBelt);
    } catch (e) {
      // ignore: avoid_print
      print('GradingCubit.eligibility: $e');
      return null;
    }
  }

  // ─────────────────────────── mutations ──────────────────────────────────────

  /// Swift: `saveScore(_ score:)`. Upserts a grading score then refreshes
  /// the score list for that session. Maps to [Repository.upsertGradingScore].
  Future<void> saveScore(GradingScore score) async {
    try {
      await _repo.upsertGradingScore(score);
      final updated = await _repo.gradingScores(score.sessionId);
      final newMap = Map<EntityID, List<GradingScore>>.from(
        state.scoresBySession,
      )..[score.sessionId] = updated;
      emit(state.copyWith(scoresBySession: newMap));
    } catch (e) {
      // ignore: avoid_print
      print('GradingCubit.saveScore: $e');
    }
  }

  /// Swift: `saveSession(_ session:)`. Upserts a grading session then
  /// refreshes sessions for the affected branch. Maps to
  /// [Repository.upsertGradingSession].
  Future<void> saveSession(GradingSession session) async {
    try {
      await _repo.upsertGradingSession(session);
      final refreshed = await _repo.gradingSessionsForBranch(session.branchId);
      final scores = await _repo.gradingScores(session.id);
      final newMap = Map<EntityID, List<GradingScore>>.from(
        state.scoresBySession,
      )..[session.id] = scores;
      emit(state.copyWith(sessions: refreshed, scoresBySession: newMap));
    } catch (e) {
      // ignore: avoid_print
      print('GradingCubit.saveSession: $e');
    }
  }

  /// Swift: `issueCertificate(athlete:sessionID:targetBelt:signedBy:)`.
  ///
  /// Creates a [GradingCertificate], persists it, then promotes the athlete
  /// by updating their [currentBelt] via [Repository.upsertAthlete]. Returns
  /// the certificate on success, null on error — matching Swift's optional
  /// return.
  ///
  /// Because [Athlete] is an immutable value type in Dart the promoted copy
  /// is fetched fresh from the repository after the upsert (instead of a
  /// local mutation) so the stored record is authoritative.
  Future<GradingCertificate?> issueCertificate({
    required Athlete athlete,
    required EntityID sessionId,
    required Belt targetBelt,
    required List<EntityID> signedBy,
  }) async {
    final cert = GradingCertificate(
      id: newEntityId(),
      athleteId: athlete.id,
      fromBelt: athlete.currentBelt,
      toBelt: targetBelt,
      awardedAt: DateTime.now(),
      sessionId: sessionId,
      signedByCoachIds: signedBy,
    );
    try {
      await _repo.issueCertificate(cert);
      // Promote the athlete: append old belt to history, set new current belt.
      // The repository owns the authoritative copy; we rebuild from the stored
      // fields using a JSON round-trip via fromJson/toJson — the same approach
      // the Swift store uses (struct copy + field mutation before upsert).
      final json = athlete.toJson();
      final history =
          (json['beltHistory'] as List? ?? [])
              .cast<Map<String, dynamic>>()
              .toList()
            ..add(athlete.currentBelt.toJson());
      json['beltHistory'] = history;
      json['currentBelt'] = targetBelt.toJson();
      final promoted = Athlete.fromJson(json);
      await _repo.upsertAthlete(promoted);
      return cert;
    } catch (e) {
      // ignore: avoid_print
      print('GradingCubit.issueCertificate: $e');
      return null;
    }
  }

  // ─────────────────────────── helpers ────────────────────────────────────────

  /// Loads scores for every session in [sessions] and returns the populated map.
  Future<Map<EntityID, List<GradingScore>>> _fetchScores(
    List<GradingSession> sessions,
  ) async {
    final result = <EntityID, List<GradingScore>>{};
    for (final s in sessions) {
      result[s.id] = await _repo.gradingScores(s.id);
    }
    return result;
  }
}
