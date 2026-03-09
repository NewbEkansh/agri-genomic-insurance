import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:yieldshield/l10n/app_localizations.dart';
import 'screens/dashboard_screen.dart';
import 'screens/alert_screen.dart';
import 'screens/payout_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const YieldShieldApp());
}

class YieldShieldApp extends StatefulWidget {
  const YieldShieldApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _YieldShieldAppState? state =
        context.findAncestorStateOfType<_YieldShieldAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<YieldShieldApp> createState() => _YieldShieldAppState();
}

class _YieldShieldAppState extends State<YieldShieldApp> {
  Locale _locale = const Locale('en');

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YieldShield',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [
        Locale('en'), Locale('hi'), Locale('ta'), Locale('te'),
        Locale('bn'), Locale('mr'), Locale('gu'), Locale('kn'),
        Locale('ml'), Locale('pa'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      // ← Start at login screen
      home: const LoginScreen(),
      // ← After login, navigate to /home
      routes: {
        '/home': (context) => const MainNav(),
      },
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ScanScreen(),
    AlertScreen(),
    PayoutScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF2E7D32).withOpacity(0.12),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard, color: Color(0xFF2E7D32)),
              label: l10n.dashboard,
            ),
            const NavigationDestination(
              icon: Icon(Icons.camera_alt_outlined),
              selectedIcon: Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
              label: 'Scan',
            ),
            NavigationDestination(
              icon: const Icon(Icons.warning_amber_outlined),
              selectedIcon: const Icon(Icons.warning_amber_rounded, color: Color(0xFF2E7D32)),
              label: l10n.alerts,
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(Icons.receipt_long, color: Color(0xFF2E7D32)),
              label: l10n.payouts,
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person, color: Color(0xFF2E7D32)),
              label: l10n.profile,
            ),
          ],
        ),
      ),
    );
  }
}