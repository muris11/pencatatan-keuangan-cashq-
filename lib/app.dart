import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'l10n/locales.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_page.dart';
import 'screens/home/dashboard_page.dart';

class AppState extends ChangeNotifier {
  L10n l10n = L10n('id');
  bool dark = false;

  void setLang(String code) {
    l10n = L10n(code);
    notifyListeners();
  }

  void setDark(bool v) {
    dark = v;
    notifyListeners();
  }
}

class CashQApp extends StatelessWidget {
  const CashQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (ctx, app, _) {
          return MaterialApp(
            title: app.l10n.appName,
            debugShowCheckedModeBanner: false,
            theme: app.dark ? darkTheme() : lightTheme(),
            home: const AuthGate(),
            builder: (context, child) {
              if (child == null) {
                return const Scaffold(
                  backgroundColor: Colors.white,
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Error loading app',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return child;
            },
          );
        },
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && !_isInitialized) {
      _initializeAuth();
    }
  }

  Future<void> _initializeAuth() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final authService = AuthService();
      if (authService.currentUser != null) {
        await authService.currentUser!.reload();
      }

      setState(() {
        _isInitialized = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }
    if (_error != null) {
      return _buildErrorScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return _buildErrorScreen('No connection to auth service');
          case ConnectionState.waiting:
            return _buildLoadingScreen();
          case ConnectionState.active:
          case ConnectionState.done:
            if (snapshot.hasError) {
              return _buildErrorScreen('Auth error: ${snapshot.error}');
            }
            final user = snapshot.data;
            if (user != null) {
              return const DashboardPage();
            } else {
              return const LoginPage();
            }
        }
      },
    );
  }

  /// LOADING SCREEN
  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Colors.white, // putih
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo dengan background putih
            SizedBox(
              height: 120,
              width: 120,
              child: Image(
                image: AssetImage('assets/images/cashq.png'),
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 32),
            Text(
              'Loading...',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }

  /// ERROR SCREEN
  Widget _buildErrorScreen([String? errorMessage]) {
    return Scaffold(
      backgroundColor: Colors.white, // putih
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Terjadi Kesalahan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? _error ?? 'Tidak dapat memuat aplikasi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isInitialized = false;
                    _error = null;
                  });
                  _initializeAuth();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text(
                  'Ke Halaman Login',
                  style: TextStyle(color: Colors.deepPurple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
