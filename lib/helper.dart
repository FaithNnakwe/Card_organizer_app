import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = "CardsDatabase.db";
  static const _databaseVersion = 1;

  // Table Names
  static const tableFolders = 'folders';
  static const tableCards = 'cards';

  // Folder Table Columns
  static const columnFolderId = 'id';
  static const columnFolderName = 'name';
  static const columnTimestamp = 'timestamp';

  // Card Table Columns
  static const columnCardId = 'id';
  static const columnCardName = 'name';
  static const columnSuit = 'suit';
  static const columnImageUrl = 'image_url';
  static const columnFolderIdFK = 'folder_id';

  late Database _db;

  Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );

    // Prepopulate database with standard deck of cards
    await _populateCards();
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableFolders (
        $columnFolderId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnFolderName TEXT NOT NULL,
        $columnTimestamp TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableCards (
        $columnCardId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnCardName TEXT NOT NULL,
        $columnSuit TEXT NOT NULL,
        $columnImageUrl TEXT NOT NULL,
        $columnFolderIdFK INTEGER,
        FOREIGN KEY ($columnFolderIdFK) REFERENCES $tableFolders($columnFolderId) ON DELETE CASCADE
      )
    ''');
  }

  // Generate image URL dynamically
  String getCardImageUrl(String rank, String suit) {
    return 'https://deckofcardsapi.com/static/img/${rank}${suit}.png'; // This is an existing card Image API. Example typing in the link ' https://deckofcardsapi.com/static/img/AS.png' 
    // generates an Ace of Spades Card. 

  }

  // Prepopulate Cards table
  Future<void> _populateCards() async {
    List<String> suits = ['H', 'D', 'S', 'C']; // Hearts, Diamonds, Spades, Clubs
    List<String> ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];

    for (var suit in suits) {
      for (var rank in ranks) {
        await _db.insert(tableCards, {
          columnCardName: '$rank of ${_getSuitName(suit)}',
          columnSuit: suit,
          columnImageUrl: getCardImageUrl(rank, suit),
          columnFolderIdFK: null // No folder assigned initially
        });
      }
    }
  }

  // Get full suit name
  String _getSuitName(String suit) {
    switch (suit) {
      case 'H':
        return 'Hearts';
      case 'D':
        return 'Diamonds';
      case 'S':
        return 'Spades';
      case 'C':
        return 'Clubs';
      default:
        return 'Unknown';
    }
  }

  // CRUD Operations

  // Insert Folder
  Future<int> insertFolder(String folderName) async {
    await init(); 
    return await _db.insert(tableFolders, {columnFolderName: folderName});
  }

  // Insert Card into Folder
  Future<int> addCardToFolder(int cardId, String newCardName, String newSuit) async {
    await init(); 
    return await _db.update(
      tableCards,
      {
      columnCardName: newCardName,
      columnSuit: newSuit,
      columnImageUrl: getCardImageUrl(newCardName, newSuit), // Dynamically update the image URL
      },
      where: '$columnCardId = ?',
      whereArgs: [cardId],
    );
  }

  // Get All Folders
  Future<List<Map<String, dynamic>>> getAllFolders() async {
    await init(); 
    return await _db.query(tableFolders);
  }

  // Get Cards in a Folder
  Future<List<Map<String, dynamic>>> getCardsInFolder(int folderId) async {
    await init(); 
    return await _db.query(
      tableCards,
      where: '$columnFolderIdFK = ?',
      whereArgs: [folderId],
    );
  }

  // Remove Card from Folder
  Future<int> removeCardFromFolder(int cardId) async {
    await init(); 
    return await _db.update(
      tableCards,
      {columnFolderIdFK: null},
      where: '$columnCardId = ?',
      whereArgs: [cardId],
    );
  }

  // Delete Folder 
  Future<int> deleteFolder(int folderId) async {
    await init(); 
    return await _db.delete(
      tableFolders,
      where: '$columnFolderId = ?',
      whereArgs: [folderId],
    );
  }

  // Delete Card Permanently
  Future<int> deleteCard(int cardId) async {
    await init(); 
    return await _db.delete(
      tableCards,
      where: '$columnCardId = ?',
      whereArgs: [cardId],
    );
  }

  Future<int> insertCard(String cardName, String suit, int folderId) async {
    await init(); 
  return await _db.insert(tableCards, {
    columnCardName: cardName,
    columnSuit: suit,
    columnImageUrl: getCardImageUrl(cardName, suit),
    columnFolderIdFK: folderId,
  });
}

}


