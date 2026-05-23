import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/blocs/session_cubit.dart';
import '../core/repository/repository.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'locator.dart';
import 'role_router.dart';

/// Port of SHJSDSCApp.swift. Provides the single global session Cubit (mirrors
/// `@Environment(AppSession)`), sets up EN/AR localization with automatic RTL
/// (Flutter flips the layout from the active locale's text direction, matching
/// the Swift HStack/VStack auto-mirroring rule), and hands off to RoleRouter.
class ShjsdscApp extends StatelessWidget {
  const ShjsdscApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SessionCubit(getIt<Repository>())..load(),
      child: MaterialApp(
        onGenerateTitle: (context) => L10n.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        localizationsDelegates: const [
          L10n.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.supportedLocales,
        home: const RoleRouter(),
      ),
    );
  }
}
