import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/theme/toyverse_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await SupabaseService.initialize();

  runApp(
    const ProviderScope(
      child: ToyVerseApp(),
    ),
  );
}

class ToyVerseApp extends StatelessWidget {
  const ToyVerseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Guild Club',
      debugShowCheckedModeBanner: false,
      theme: ToyVerseTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
