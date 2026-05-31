import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../models/branch.dart';
import '../models/branch_compliance.dart';
import '../models/branch_facility.dart';
import '../models/branch_financials.dart';
import '../models/branch_hours.dart';
import '../models/branch_inventory.dart';
import '../models/branch_media.dart';
import '../models/branch_milestone.dart';
import '../models/branch_pricing.dart';
import '../models/branch_program.dart';
import '../models/branch_safeguarding.dart';
import '../models/branch_social_links.dart';
import '../models/coach.dart';
import '../models/entity_id.dart';
import '../models/schedule.dart';
import '../repository/repository.dart';
import '../services/branch_metrics.dart';

/// Port of Core/Stores/BranchProfileStore.swift.
///
/// Loads the full operational dossier for one branch — all sub-sections are
/// fetched concurrently (via parallel `Future.wait`), matching the Swift
/// `async let` fan-out pattern. [BranchOperationalMetrics] are computed from
/// the loaded data using [BranchMetrics.compute].

// ──────────────────────────────────────────────────────────────────────────────
// State
// ──────────────────────────────────────────────────────────────────────────────

enum BranchProfileStatus { initial, loading, ready, failed }

class BranchProfileState extends Equatable {
  final BranchProfileStatus status;
  final Branch? branch;
  final BranchFacility? facility;
  final BranchHours? hours;
  final List<BranchProgram> programs;
  final BranchInventory? inventory;
  final BranchCompliance? compliance;
  final BranchPricing? pricing;
  final List<BranchFinancials> financials;
  final BranchMedia? media;
  final BranchSocialLinks? socialLinks;
  final BranchSafeguarding? safeguarding;
  final List<BranchMilestone> milestones;
  final List<Coach> coaches;
  final BranchOperationalMetrics metrics;

  const BranchProfileState({
    this.status = BranchProfileStatus.initial,
    this.branch,
    this.facility,
    this.hours,
    this.programs = const [],
    this.inventory,
    this.compliance,
    this.pricing,
    this.financials = const [],
    this.media,
    this.socialLinks,
    this.safeguarding,
    this.milestones = const [],
    this.coaches = const [],
    this.metrics = BranchOperationalMetrics.empty,
  });

  BranchProfileState copyWith({
    BranchProfileStatus? status,
    Branch? branch,
    BranchFacility? facility,
    BranchHours? hours,
    List<BranchProgram>? programs,
    BranchInventory? inventory,
    BranchCompliance? compliance,
    BranchPricing? pricing,
    List<BranchFinancials>? financials,
    BranchMedia? media,
    BranchSocialLinks? socialLinks,
    BranchSafeguarding? safeguarding,
    List<BranchMilestone>? milestones,
    List<Coach>? coaches,
    BranchOperationalMetrics? metrics,
  }) => BranchProfileState(
    status: status ?? this.status,
    branch: branch ?? this.branch,
    facility: facility ?? this.facility,
    hours: hours ?? this.hours,
    programs: programs ?? this.programs,
    inventory: inventory ?? this.inventory,
    compliance: compliance ?? this.compliance,
    pricing: pricing ?? this.pricing,
    financials: financials ?? this.financials,
    media: media ?? this.media,
    socialLinks: socialLinks ?? this.socialLinks,
    safeguarding: safeguarding ?? this.safeguarding,
    milestones: milestones ?? this.milestones,
    coaches: coaches ?? this.coaches,
    metrics: metrics ?? this.metrics,
  );

  @override
  List<Object?> get props => [
    status,
    branch?.id,
    facility,
    hours,
    programs,
    inventory,
    compliance,
    pricing,
    financials,
    media,
    socialLinks,
    safeguarding,
    milestones,
    coaches,
    metrics,
  ];
}

// ──────────────────────────────────────────────────────────────────────────────
// Cubit
// ──────────────────────────────────────────────────────────────────────────────

class BranchProfileCubit extends Cubit<BranchProfileState> {
  final Repository _repo;

  BranchProfileCubit(this._repo) : super(const BranchProfileState());

  /// Load the full branch dossier. All independent repository reads are issued
  /// concurrently via [Future.wait], mirroring the Swift `async let` fan-out.
  Future<void> load(EntityID branchId, {int monthsBack = 12}) async {
    emit(state.copyWith(status: BranchProfileStatus.loading));
    try {
      // Fan out all independent reads in parallel.
      final results = await Future.wait([
        _repo.branch(branchId), // 0
        _repo.facility(branchId), // 1
        _repo.hours(branchId), // 2
        _repo.programs(branchId), // 3
        _repo.inventory(branchId), // 4
        _repo.compliance(branchId), // 5
        _repo.pricing(branchId), // 6
        _repo.financials(branchId, monthsBack), // 7
        _repo.media(branchId), // 8
        _repo.socialLinks(branchId), // 9
        _repo.safeguarding(branchId), // 10
        _repo.milestones(branchId), // 11
        _repo.coachesInBranch(branchId), // 12
        _repo.athletesInBranch(branchId), // 13
        _sessionsThisWeek(branchId), // 14
      ]);

      final branch = results[0] as Branch?;
      final facility = results[1] as BranchFacility?;
      final hours = results[2] as BranchHours?;
      final programs = results[3] as List<BranchProgram>;
      final inventory = results[4] as BranchInventory?;
      final compliance = results[5] as BranchCompliance?;
      final pricing = results[6] as BranchPricing?;
      final financials = results[7] as List<BranchFinancials>;
      final media = results[8] as BranchMedia?;
      final socialLinks = results[9] as BranchSocialLinks?;
      final safeguarding = results[10] as BranchSafeguarding?;
      final milestones = results[11] as List<BranchMilestone>;
      final coaches = results[12] as List<Coach>;
      final athletes = results[13] as List<dynamic>;
      final sessions = results[14] as List<ClassSession>;

      // Pull a 30-day attendance window for metrics. We union per athlete —
      // acceptable for demo size; Stage 5 will expose a direct by-branch query.
      final cutoff = DateTime.now().subtract(const Duration(days: 30));
      final allAttendance = <AttendanceRecord>[];
      await Future.wait(
        athletes.map((a) async {
          try {
            final recs = await _repo.attendanceForAthlete(a.id, cutoff);
            allAttendance.addAll(recs);
          } catch (_) {}
        }),
      );

      BranchOperationalMetrics metrics = BranchOperationalMetrics.empty;
      if (branch != null) {
        metrics = BranchMetrics.compute(
          branch: branch,
          athletes: List.from(athletes),
          attendance: allAttendance,
          sessions: sessions,
          coaches: coaches,
        );
      }

      emit(
        BranchProfileState(
          status: BranchProfileStatus.ready,
          branch: branch,
          facility: facility,
          hours: hours,
          programs: programs,
          inventory: inventory,
          compliance: compliance,
          pricing: pricing,
          financials: financials,
          media: media,
          socialLinks: socialLinks,
          safeguarding: safeguarding,
          milestones: milestones,
          coaches: coaches,
          metrics: metrics,
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('BranchProfileCubit.load: $e');
      emit(state.copyWith(status: BranchProfileStatus.failed));
    }
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Collect all sessions across the current calendar week (Sun–Sat, 7 days).
  Future<List<ClassSession>> _sessionsThisWeek(EntityID branchId) async {
    final now = DateTime.now();
    // weekday: Mon=1…Sun=7; shift to Sun=0 baseline.
    final daysSinceSunday = now.weekday % 7;
    final weekStart = now.subtract(Duration(days: daysSinceSunday));
    final out = <ClassSession>[];
    await Future.wait(
      List.generate(7, (offset) async {
        final day = weekStart.add(Duration(days: offset));
        try {
          final sessions = await _repo.sessionsForBranch(branchId, day);
          out.addAll(sessions);
        } catch (_) {}
      }),
    );
    return out;
  }
}
