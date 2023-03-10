import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import 'package:namaadhu_app/callback_dispatcher.dart';
import 'package:namaadhu_app/src/constants/app_colors.dart';
import 'package:namaadhu_app/src/features/select_island/models/atoll.dart';
import 'package:namaadhu_app/src/features/select_island/models/island.dart';
import 'package:namaadhu_app/src/features/select_island/providers/selected_island_provider.dart';
import 'package:namaadhu_app/src/features/select_island/screens/custom_search_delegate.dart';
import 'package:namaadhu_app/src/router/app_router.dart';
import 'package:namaadhu_app/src/services/notification_service.dart';
import 'package:namaadhu_app/src/common_widgets/custom_expansion_tile.dart';
import 'package:workmanager/workmanager.dart';

class SelectIslandScreen extends ConsumerStatefulWidget {
  const SelectIslandScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _SelectIslandScreenState();
}

class _SelectIslandScreenState extends ConsumerState<SelectIslandScreen> {
  @override
  void initState() {
    super.initState();
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled()
        .then((isAllowed) {
      if (!isAllowed!) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: kCardColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(10.0),
              ),
            ),
            title: const Text('Allow notifications'),
            content:
                const Text('Our app would like to show prayer time reminders'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Don/t Allow',
                  style: TextStyle(
                    color: kMutedColor,
                    fontSize: 18.0,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  flutterLocalNotificationsPlugin
                      .resolvePlatformSpecificImplementation<
                          AndroidFlutterLocalNotificationsPlugin>()
                      ?.requestPermission()
                      .then((_) => Navigator.pop(context));
                },
                child: const Text(
                  'Allow',
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // System nav bar color
    final systemTheme = SystemUiOverlayStyle.light
        .copyWith(systemNavigationBarColor: kBackgroundColor);

    final selectedIsland = ref.watch(selectedIslandProvider);
    final islandList = ref.watch(islandsProvider);
    final atollList = ref.watch(atollsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Select Island',
          ),
          centerTitle: true,
          leading: selectedIsland.id != -1
              ? IconButton(
                  icon: const Icon(Ionicons.chevron_back),
                  onPressed: () => context.goNamed(AppRoute.home.name),
                )
              : null,
          actions: [
            IconButton(
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: CustomSearchDelegate(islandList, atollList),
                );
              },
              icon: const Icon(Ionicons.search),
            ),
          ],
        ),
        body: ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: atollList.length,
          itemBuilder: (context, index) {
            Atoll atoll = atollList[index];
            List<Island> islandsFromAtoll = islandList
                .where((element) => element.atollNumber == atoll.id)
                .toList();

            return CustomExpansionTile(
              title: Text('${atoll.atollName} (${atoll.atollAbbreviation})'),
              children: [
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: islandsFromAtoll.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        final selectedIslandNotifier =
                            ref.watch(selectedIslandProvider.notifier);

                        selectedIslandNotifier.setSelectedIsland(
                          id: islandsFromAtoll[index].id,
                          atollAbbreviation: atoll.atollAbbreviation,
                          islandName: islandsFromAtoll[index].islandName,
                        );

                        NotificationService().cancelScheduledNotifications();

                        // Re-register background task
                        Workmanager()
                            .cancelByUniqueName(prayerTimeShedulerTask);
                        Workmanager().registerPeriodicTask(
                          prayerTimeShedulerTask,
                          prayerTimeShedulerTask,
                          frequency: const Duration(minutes: 15),
                        );

                        context.goNamed(AppRoute.home.name);
                      },
                      title: Padding(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Text(
                          '${atoll.atollAbbreviation}. ${islandsFromAtoll[index].islandName}',
                        ),
                      ),
                    );
                  },
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
