import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:keysoc_code_test/song_list_model.dart';

enum sortBy { sortByTrackName, sortByCollectionName }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Song List'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Result> songList = [];
  List<Result> filteredSongList = [];

  final spacing = const SizedBox(width: 10);
  sortBy currentSortBy = sortBy.sortByTrackName;

  Future<List<Result>> fetchSongList() async {
    const String url =
        'https://itunes.apple.com/search?term=Taylor+Swift&limit=200&media=music';
    late SongList responseData = SongList(resultCount: 0, results: []);
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        responseData = SongList.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to load data: $e');
    }

    return sortListByTrackName(responseData.results);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [buildSortButton()],
      ),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              buildSearchView(),
              SizedBox(height: 10),
              Expanded(child: buildFutuerView())
            ],
          )),
    );
  }

  Widget buildFutuerView() {
    return FutureBuilder<List<Result>>(
      future: fetchSongList(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (songList.isEmpty) {
            songList = snapshot.data!;
            filteredSongList = songList;
          }
          return buildList();
        } else {
          return const Text("No data available");
        }
      },
    );
  }

  Widget buildList() {
    return ListView.builder(
      itemCount: filteredSongList.length,
      itemBuilder: (context, index) {
        final song = filteredSongList[index];
        return Row(
          children: [
            Expanded(flex: 1, child: Image.network(song.artworkUrl100!)),
            spacing,
            Expanded(
              flex: 3,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Song Name: ${song.trackName!}"),
                    spacing,
                    Text("Album Name: ${song.collectionName!}")
                  ]),
            ),
          ],
        );
      },
    );
  }

  Widget buildSearchView() {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Search',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) {
        filterSong(value);
      },
    );
  }

  void selectSorting(sortBy value) {
    setState(() {
      currentSortBy = value;
      switch (currentSortBy) {
        case sortBy.sortByTrackName:
          filteredSongList = sortListByTrackName(songList);
          break;
        case sortBy.sortByCollectionName:
          filteredSongList = sortListByCollectionName(songList);
          break;
      }
    });
    Navigator.pop(context);
  }

  Widget buildSortButton() {
    return PopupMenuButton<sortBy>(
      onSelected: selectSorting,
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<sortBy>(
            child: Row(
              children: [
                Radio<sortBy>(
                  value: sortBy.sortByTrackName,
                  groupValue: currentSortBy,
                  onChanged: (value) {
                    selectSorting(value!);
                  },
                ),
                Text('Sort by Song Name'),
              ],
            ),
          ),
          PopupMenuItem<sortBy>(
            child: Row(
              children: [
                Radio<sortBy>(
                  value: sortBy.sortByCollectionName,
                  groupValue: currentSortBy,
                  onChanged: (value) {
                    selectSorting(value!);
                  },
                ),
                Text('Sort by Album Name'),
              ],
            ),
          ),
        ];
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Icon(Icons.sort_by_alpha),
      ),
    );
  }

  List<Result> sortListByTrackName(List<Result> dataList) {
    dataList.sort((a, b) => a.trackName!.compareTo(b.trackName!));
    return dataList;
  }

  List<Result> sortListByCollectionName(List<Result> dataList) {
    dataList.sort((a, b) => a.collectionName!.compareTo(b.collectionName!));
    return dataList;
  }

  void filterSong(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredSongList = songList;
      });
    } else {
      setState(() {
        filteredSongList = songList
            .where((item) =>
                item.trackName!.toLowerCase().contains(query.toLowerCase()) ||
                item.collectionName!
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      });
    }
  }
}
