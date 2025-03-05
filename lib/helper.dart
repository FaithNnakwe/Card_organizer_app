import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Define a class to handle the database operations
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  // Private constructor for Singleton pattern
  DatabaseHelper._internal();

  // Getter for the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cards_database.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _createTables(db);
        await _insertSampleData(db);
      },
    );
  }

  // Create tables for Folders and Cards
  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE Folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_name TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE Cards(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        image_url TEXT NOT NULL,
        folder_id INTEGER,
        FOREIGN KEY (folder_id) REFERENCES Folders(id)
      )
    ''');
  }

  // Prepopulate Cards table with standard deck of cards
  Future<void> _insertSampleData(Database db) async {
    // Folders
    await db.insert('Folders', {'folder_name': 'Hearts', 'timestamp': DateTime.now().millisecondsSinceEpoch});
    await db.insert('Folders', {'folder_name': 'Spades', 'timestamp': DateTime.now().millisecondsSinceEpoch});
    await db.insert('Folders', {'folder_name': 'Diamonds', 'timestamp': DateTime.now().millisecondsSinceEpoch});
    await db.insert('Folders', {'folder_name': 'Clubs', 'timestamp': DateTime.now().millisecondsSinceEpoch});

    // Get the folder IDs
    List<Map<String, dynamic>> folderResult = await db.query('Folders');
    int heartsFolderId = folderResult.firstWhere((folder) => folder['folder_name'] == 'Hearts')['id'];
    int spadesFolderId = folderResult.firstWhere((folder) => folder['folder_name'] == 'Spades')['id'];
    int diamondsFolderId = folderResult.firstWhere((folder) => folder['folder_name'] == 'Diamonds')['id'];
    int clubsFolderId = folderResult.firstWhere((folder) => folder['folder_name'] == 'Clubs')['id'];

    // Cards data (using URLs for simplicity)
    List<Map<String, dynamic>> cardsData = [];
    List<String> suits = ['Hearts', 'Spades', 'Diamonds', 'Clubs'];
    List<String> ranks = ['Ace', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King'];

    for (var suit in suits) {
      for (var i = 0; i < ranks.length; i++) {
        String cardName = '${ranks[i]} of $suit';
        String imageUrl = 'assets/images/${ranks[i]}_of_$suit.png';  // Assuming images are named like 'Ace_of_Hearts.png'
        int folderId;

        switch (suit) {
          case 'Hearts':
            folderId = heartsFolderId;
            break;
          case 'Spades':
            folderId = spadesFolderId;
            break;
          case 'Diamonds':
            folderId = diamondsFolderId;
            break;
          case 'Clubs':
            folderId = clubsFolderId;
            break;
          default:
            folderId = heartsFolderId; // Default to Hearts if not found
        }

        cardsData.add({
          'name': cardName,
          'suit': suit,
          'image_url': imageUrl,
          'folder_id': folderId,
        });
      }
    }

    // Insert cards data
    for (var card in cardsData) {
      await db.insert('Cards', card);
    }
  }

  // Update Folder: Update the folder's name and timestamp
Future<void> updateFolder(int id, String newFolderName) async {
  final db = await database;
  
  await db.update(
    'Folders',
    {
      'folder_name': newFolderName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    },
    where: 'id = ?',
    whereArgs: [id],
  );
}

// Update Card: Update a card's name, suit, or image URL by card ID
Future<void> updateCard(int id, {String? newName, String? newSuit, String? newImageUrl}) async {
  final db = await database;

  Map<String, dynamic> updatedCard = {};
  if (newName != null) updatedCard['name'] = newName;
  if (newSuit != null) updatedCard['suit'] = newSuit;
  if (newImageUrl != null) updatedCard['image_url'] = newImageUrl;

  await db.update(
    'Cards',
    updatedCard,
    where: 'id = ?',
    whereArgs: [id],
  );
}

// Delete Folder: Delete a folder by its ID
Future<void> deleteFolder(int id) async {
  final db = await database;

  // First, delete all cards in the folder to avoid foreign key constraint errors
  await db.delete(
    'Cards',
    where: 'folder_id = ?',
    whereArgs: [id],
  );

  // Then delete the folder itself
  await db.delete(
    'Folders',
    where: 'id = ?',
    whereArgs: [id],
  );
}

// Delete Card: Delete a card by its ID
Future<void> deleteCard(int id) async {
  final db = await database;

  // Delete the card from the Cards table
  await db.delete(
    'Cards',
    where: 'id = ?',
    whereArgs: [id],
  );
}

}
 

 
