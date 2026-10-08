import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'workspace/workspace_store.dart';
import 'workspace/workspace_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = WorkspaceStore(await SharedPreferences.getInstance())
    ..restore();
  runApp(RetailInventoryApp(store: store));
}

class RetailInventoryApp extends StatelessWidget {
  const RetailInventoryApp({super.key, required this.store});
  final WorkspaceStore store;
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: store,
    child: MaterialApp(
      title: 'GOODIE AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const WorkspaceScreen(),
    ),
  );
}
