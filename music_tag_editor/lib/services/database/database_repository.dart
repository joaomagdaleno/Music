import 'package:sqflite/sqflite.dart';

/// Base class for all database repositories.
abstract class DatabaseRepository {
  final Future<Database> Function() getDatabase;

  DatabaseRepository(this.getDatabase);

  /// Helper to get the database instance.
  Future<Database> get db async => await getDatabase();
}
