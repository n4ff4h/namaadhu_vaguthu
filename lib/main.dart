import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namaadhu_app/callback_dispatcher.dart';
import 'package:namaadhu_app/src/services/data_service.dart';
import 'package:namaadhu_app/src/features/select_island/models/atoll.dart';
import 'package:namaadhu_app/src/features/select_island/models/island.dart';
import 'package:namaadhu_app/src/global_providers.dart';
import 'package:namaadhu_app/src/services/notification_service.dart';
import 'package:namaadhu_app/src/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  final islandList = await DataService().getAllIslands();
  final atollList = await DataService().getAllAtolls();

  await NotificationService().initializePlatformNotifications();

  Workmanager().initialize(callbackDispatcher);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        islandsProvider.overrideWithValue(islandList),
        atollsProvider.overrideWithValue(atollList),
      ],
      child: const NamaadhuApp(),
    ),
  );
}
