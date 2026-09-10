import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/expenses/models/transaction_model.dart';
import '../../features/expenses/models/pending_sms_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_expense.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        account TEXT NOT NULL,
        paymentType TEXT NOT NULL,
        isIncome INTEGER NOT NULL,
        monthYear TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 1,
        rawSms TEXT,
        notes TEXT
      )
    ''');

    // 2. Pending SMS Table
    await db.execute('''
      CREATE TABLE pending_sms (
        id TEXT PRIMARY KEY,
        merchant TEXT NOT NULL,
        amount REAL NOT NULL,
        paymentMode TEXT NOT NULL,
        timeString TEXT NOT NULL,
        timeAgo TEXT NOT NULL,
        suggestedCategory TEXT NOT NULL,
        bankSource TEXT NOT NULL,
        isSecondCard INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 3. Categories Table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        iconCode INTEGER NOT NULL,
        colorHex INTEGER NOT NULL,
        isCustom INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Seed initial statement transactions
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final batch = db.batch();

    // Seed September 2024 Transactions
    final initialTxns = [
      TransactionModel(
        title: 'Amazon',
        amount: -1299.0,
        category: 'Shopping',
        dateTime: '2024-09-03T10:42:00',
        account: 'HDFC ••4021',
        paymentType: 'UPI',
        isIncome: false,
        monthYear: 'September 2024',
        rawSms: 'Rs 1299.00 debited from HDFC Bank A/C **4021 on 03-Sep-24 via UPI txn to AMAZON.',
      ),
      TransactionModel(
        title: 'Rahul',
        amount: -500.0,
        category: 'Food',
        dateTime: '2024-09-03T09:15:00',
        account: 'Google Pay',
        paymentType: 'UPI',
        isIncome: false,
        monthYear: 'September 2024',
        rawSms: 'Sent Rs.500 to Rahul via Google Pay UPI.',
      ),
      TransactionModel(
        title: 'Swiggy',
        amount: -420.0,
        category: 'Food',
        dateTime: '2024-09-03T13:20:00',
        account: 'ICICI ••8912',
        paymentType: 'Card',
        isIncome: false,
        monthYear: 'September 2024',
      ),
      TransactionModel(
        title: 'Uber',
        amount: -340.0,
        category: 'Travel',
        dateTime: '2024-09-02T20:20:00',
        account: 'Paytm UPI',
        paymentType: 'UPI',
        isIncome: false,
        monthYear: 'September 2024',
      ),
      TransactionModel(
        title: 'Salary',
        amount: 50000.0,
        category: 'Salary',
        dateTime: '2024-09-02T10:00:00',
        account: 'HDFC Salary',
        paymentType: 'Bank Transfer',
        isIncome: true,
        monthYear: 'September 2024',
      ),
      // October 2024 Transactions
      TransactionModel(
        title: 'Netflix',
        amount: -649.0,
        category: 'Entertainment',
        dateTime: '2024-10-01T15:30:00',
        account: 'ICICI ••8912',
        paymentType: 'Card',
        isIncome: false,
        monthYear: 'October 2024',
      ),
      TransactionModel(
        title: 'Starbucks',
        amount: -350.0,
        category: 'Food',
        dateTime: '2024-10-02T11:15:00',
        account: 'Google Pay',
        paymentType: 'UPI',
        isIncome: false,
        monthYear: 'October 2024',
      ),
      TransactionModel(
        title: 'Freelance Project',
        amount: 25000.0,
        category: 'Salary',
        dateTime: '2024-10-02T16:00:00',
        account: 'HDFC Salary',
        paymentType: 'Bank Transfer',
        isIncome: true,
        monthYear: 'October 2024',
      ),
    ];

    for (final tx in initialTxns) {
      batch.insert('transactions', tx.toMap());
    }

    // Seed Pending SMS queue
    final initialSms = [
      PendingSmsModel(
        id: 'sms_1',
        merchant: 'Rahul',
        amount: 500.0,
        paymentMode: 'UPI',
        timeString: '03 Sep, 09:15 AM',
        timeAgo: 'Just now',
        suggestedCategory: 'Food',
        bankSource: 'Detected from HDFC Bank SMS',
        isSecondCard: false,
      ),
      PendingSmsModel(
        id: 'sms_2',
        merchant: 'Amazon',
        amount: 1299.0,
        paymentMode: 'Card',
        timeString: 'Today, 10:42 AM',
        timeAgo: '12m ago',
        suggestedCategory: 'Shopping',
        bankSource: 'Detected from ICICI Bank SMS',
        isSecondCard: true,
      ),
    ];

    for (final sms in initialSms) {
      batch.insert('pending_sms', sms.toMap());
    }

    await batch.commit(noResult: true);
  }

  Future<int> getTransactionCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM transactions');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (_) {
      return 8;
    }
  }

  Future<double> getDatabaseSizeMb() async {
    try {
      final dbPath = await getDatabasesPath();
      final file = File(join(dbPath, 'smart_expense.db'));
      if (await file.exists()) {
        final bytes = await file.length();
        final mb = bytes / (1024 * 1024);
        return double.parse(mb.toStringAsFixed(2));
      }
    } catch (_) {}
    return 0.05; // Default minimal initial size in MB
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
