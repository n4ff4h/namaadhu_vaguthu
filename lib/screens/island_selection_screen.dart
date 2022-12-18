import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:namaadhu_vaguthu/global_providers.dart';
import 'package:namaadhu_vaguthu/models/atoll.dart';
import 'package:namaadhu_vaguthu/models/island.dart';
import 'package:namaadhu_vaguthu/providers/selected_island_provider.dart';

class IslandSelectionScreen extends ConsumerWidget {
  const IslandSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Island',
        ),
      ),
      body: FutureBuilder(
        future: Future.wait([
          ref.watch(islandsProvider),
          ref.watch(atollsProvider),
        ]),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            // snapshot.data![x] is a list of objects
            List<Island> islands = snapshot.data![0];
            List<Atoll> atolls = snapshot.data![1];

            return ListView.builder(
              scrollDirection: Axis.vertical,
              shrinkWrap: true,
              itemCount: atolls.length,
              itemBuilder: (context, index) {
                Atoll atoll = atolls[index];
                List<Island> islandsFromAtoll = islands
                    .where((element) => element.atollNumber == atoll.id)
                    .toList();

                return ExpansionTile(
                  title:
                      Text('${atoll.atollName} (${atoll.atollAbbreviation})'),
                  children: [
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: islandsFromAtoll.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () {
                            ref
                                .watch(selectedIslandProvider.notifier)
                                .setSelectedIslandId(
                                    islandsFromAtoll[index].id);
                            Navigator.pop(context);
                          },
                          title: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text(
                                '${atoll.atollAbbreviation}.  ${islandsFromAtoll[index].islandName}'),
                          ),
                        );
                      },
                    )
                  ],
                );
              },
            );
          } else if (snapshot.hasError) {
            return Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 60,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text('Error: ${snapshot.error}'),
                ),
              ],
            );
          } else {
            return Column(
              children: const [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Awaiting result...'),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
