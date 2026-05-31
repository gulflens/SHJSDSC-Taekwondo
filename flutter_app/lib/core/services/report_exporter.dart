import 'dart:convert';

import '../models/athlete.dart';
import '../models/branch.dart';
import '../models/entity_id.dart';
import '../models/match.dart';
import '../models/tournament.dart';
import '../models/user.dart';
import 'score_engine.dart';

/// 1:1 port of Core/Services/ReportExporter.swift.
///
/// Pure CSV / JSON export logic. PDF generation requires platform rendering
/// (`ImageRenderer` in SwiftUI, a PDF package in Flutter) — see the
/// TODO(platform) note on [CsvReportExporter.exportBranchPerformance].
///
/// All methods return a [String] (the CSV / JSON payload). The platform layer
/// is responsible for writing to a file, sharing via the share-sheet, etc.

enum ExportFormat {
  csv,
  pdf;

  String get labelKey => 'export.$name';
  String get fileExtension => name;
  String get mimeType => switch (this) {
    ExportFormat.csv => 'text/csv',
    ExportFormat.pdf => 'application/pdf',
  };
}

/// Lightweight summary of one branch used by the report exporter. Mirrors
/// `BranchSummary` from Core/Stores/BranchesStore.swift (which lives in the
/// store layer of the Swift app).
class BranchSummary {
  final EntityID id;
  final Branch branch;
  final double composite;
  final LetterGrade grade;
  final int athleteCount;
  final double utilisation;

  const BranchSummary({
    required this.id,
    required this.branch,
    required this.composite,
    required this.grade,
    required this.athleteCount,
    required this.utilisation,
  });
}

/// Contract for all report exporters. Returns a UTF-8 [String] (CSV or JSON).
/// TODO(platform): the platform layer converts the String to bytes, writes
/// to a temp file, and triggers the system share-sheet.
abstract class ReportExporter {
  String exportAthletes(List<Athlete> athletes, ExportFormat format);

  String exportTournamentResults({
    required Tournament tournament,
    required List<TournamentRegistration> registrations,
    required List<Athlete> athletes,
    required List<Match> matches,
    ExportFormat format,
  });

  String exportBranchPerformance({
    required List<Branch> branches,
    required List<BranchSummary> summaries,
    ExportFormat format,
  });

  String exportMyData({
    required User user,
    Athlete? athlete,
    required List<TournamentRegistration> registrations,
    required List<Match> matches,
  });
}

/// CSV-only baseline implementation. PDF returns the same CSV payload —
/// the platform-native PDF rendering lives in the widget layer.
/// Keeping this pure-Dart ensures lib/core stays UI-free.
class CsvReportExporter implements ReportExporter {
  const CsvReportExporter();

  @override
  String exportAthletes(List<Athlete> athletes, ExportFormat format) {
    const header =
        'id,full_name,full_name_ar,branch_id,coach_id,belt,age,weight_kg,status\n';
    final rows = athletes
        .map((a) {
          return [
            a.id,
            _escape(a.fullName),
            _escape(a.fullNameAr),
            a.branchId,
            a.primaryCoachId ?? '',
            a.currentBelt.label,
            a.age.toString(),
            a.weightKg.toString(),
            a.status.name,
          ].join(',');
        })
        .join('\n');
    return header + rows;
  }

  @override
  String exportTournamentResults({
    required Tournament tournament,
    required List<TournamentRegistration> registrations,
    required List<Athlete> athletes,
    required List<Match> matches,
    ExportFormat format = ExportFormat.csv,
  }) {
    final athleteById = Map.fromEntries(athletes.map((a) => MapEntry(a.id, a)));
    final lines = <String>[];
    lines.add('# tournament: ${_escape(tournament.name)}');
    lines.add('# starts_at: ${tournament.startsAt.toIso8601String()}');
    lines.add('');
    lines.add('athlete,weight_category,seed,status');
    for (final r in registrations) {
      final name = athleteById[r.athleteId]?.fullName ?? r.athleteId;
      lines.add(
        [
          _escape(name),
          r.weightCategory.name,
          r.seedRank?.toString() ?? '',
          r.status.name,
        ].join(','),
      );
    }
    lines.add('');
    lines.add('athlete,opponent,our_score,opp_score,won,medal,date');
    for (final m in matches) {
      final athleteName =
          athleteById[m.ourAthleteId]?.fullName ?? m.ourAthleteId;
      lines.add(
        [
          _escape(athleteName),
          _escape(m.opponentName ?? '—'),
          m.ourScore.toString(),
          m.opponentScore.toString(),
          m.won ? '1' : '0',
          m.medal.name,
          m.date.toIso8601String(),
        ].join(','),
      );
    }
    return lines.join('\n');
  }

  @override
  String exportBranchPerformance({
    required List<Branch> branches,
    required List<BranchSummary> summaries,
    ExportFormat format = ExportFormat.csv,
  }) {
    // TODO(platform): PDF rendering is deferred — implement in the platform
    // stage using a PDF generation package (e.g. pdf/printing).
    const header = 'code,name,name_ar,athletes,utilisation,composite,grade\n';
    final rows = summaries
        .map((s) {
          return [
            s.branch.code,
            _escape(s.branch.name),
            _escape(s.branch.nameAr),
            s.athleteCount.toString(),
            s.utilisation.toStringAsFixed(2),
            s.composite.toStringAsFixed(1),
            s.grade.label,
          ].join(',');
        })
        .join('\n');
    return header + rows;
  }

  @override
  String exportMyData({
    required User user,
    Athlete? athlete,
    required List<TournamentRegistration> registrations,
    required List<Match> matches,
  }) {
    final bundle = {
      'user': user.toJson(),
      'athlete': athlete?.toJson(),
      'registrations': registrations.map((r) => r.toJson()).toList(),
      'matches': matches.map((m) => m.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(bundle);
  }

  String _escape(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}
