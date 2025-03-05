import 'package:flutter/material.dart';

import 'helper.dart';

final dbHelper = DatabaseHelper();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dbHelper.database;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Folders',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Card Folders'),
    );
  }
}

class CardModel {
  final int id;
  final String name;
  final String suit;
  final String imageUrl;
  final int folderId;

  CardModel({
    required this.id,
    required this.name,
    required this.suit,
    required this.imageUrl,
    required this.folderId,
  });
}

class FolderModel {
  final int id;
  final String name;
  final List<CardModel> cards;

  FolderModel({required this.id, required this.name, required this.cards});
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<FolderModel> folders = [];

  @override
  void initState() {
    super.initState();
    _loadFoldersAndCards();
  }

  Future<void> _loadFoldersAndCards() async {
    final db = await dbHelper.database;
    final folderResults = await db.query('Folders');
    final cardResults = await db.query('Cards');

    List<FolderModel> loadedFolders =
        folderResults.map((folder) {
          List<CardModel> folderCards =
              cardResults
                  .where((card) => card['folder_id'] == folder['id'])
                  .map(
                    (card) => CardModel(
                      id: card['id'] as int,
                      name: card['name'] as String,
                      suit: card['suit'] as String,
                      imageUrl: card['image_url'] as String,
                      folderId: card['folder_id'] as int,
                    ),
                  )
                  .toList();

          return FolderModel(
            id: folder['id'] as int,
            name: folder['folder_name'] as String,
            cards: folderCards,
          );
        }).toList();

    if (!mounted) return;
    setState(() {
      folders = loadedFolders;
    });
  }

  Future<void> _deleteCard(int cardId) async {
    await dbHelper.deleteCard(cardId);
    await _loadFoldersAndCards(); // Await to ensure data reloads properly
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body:
          folders.isEmpty
              ? const Center(child: Text('No folders available'))
              : ListView.builder(
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  return ExpansionTile(
                    leading:
                        folder.cards.isNotEmpty
                            ? Image.asset(
                              folder.cards.first.imageUrl,
                              width: 40,
                              height: 40,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      const Icon(Icons.error),
                            )
                            : const Icon(Icons.folder),
                    title: Text(folder.name),
                    subtitle: Text('${folder.cards.length} cards'),
                    children:
                        folder.cards.map((card) {
                          return ListTile(
                            leading: Image.asset(
                              card.imageUrl,
                              width: 40,
                              height: 40,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      const Icon(Icons.error),
                            ),
                            title: Text(card.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteCard(card.id),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
    );
  }
}
