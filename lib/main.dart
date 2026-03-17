import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dialer_app_poc/app.dart';
import 'package:dialer_app_poc/core/constants/app_constants.dart';
import 'package:dialer_app_poc/features/call_history/data/models/call_history_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Adapters
  Hive.registerAdapter(CallHistoryModelAdapter());
  
  // Open Boxes
  await Hive.openBox<CallHistoryModel>(AppConstants.callHistoryBox);
  
  runApp(
    const ProviderScope(
      child: CRMApp(),
    ),
  );
}
