import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/prediction_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/analytics_provider.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  runApp(const RetailInventoryApp());
}

class RetailInventoryApp extends StatelessWidget {
  const RetailInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => PredictionProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
      ],
      child: MaterialApp(
        title: 'Retail Inventory AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
