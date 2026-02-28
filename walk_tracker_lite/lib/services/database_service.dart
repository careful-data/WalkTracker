import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/walk_session.dart';
import '../models/route_point.dart';

class DatabaseService {
  Database? _db;
  static const String _dbName = 'walk_tracker_lite.db';
  static const int _dbVersion = 1;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        distance_meters REAL NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE route_points (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        accuracy REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_route_points_session ON route_points(session_id)',
    );
  }

  Future<int> insertSession(WalkSession session) async {
    final database = await db;
    return database.insert('sessions', session.toMap());
  }

  Future<int> updateSession(WalkSession session) async {
    final database = await db;
    return database.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteSession(WalkSession session) async {
    final database = await db;
    await database.delete(
      'route_points',
      where: 'session_id = ?',
      whereArgs: [session.id],
    );
    return database.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<List<WalkSession>> getAllSessions() async {
    final database = await db;
    final maps = await database.query(
      'sessions',
      orderBy: 'start_time DESC',
    );
    return maps.map((m) => WalkSession.fromMap(m)).toList();
  }

  Future<int> insertRoutePoint(RoutePoint point) async {
    final database = await db;
    return database.insert('route_points', point.toMap());
  }

  Future<List<RoutePoint>> getRoutePoints(int sessionId) async {
    final database = await db;
    final maps = await database.query(
      'route_points',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => RoutePoint.fromMap(m)).toList();
  }

  Future<int> deleteRoutePoints(int sessionId) async {
    final database = await db;
    return database.delete(
      'route_points',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }
}
