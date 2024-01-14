import 'package:mongo_dart/mongo_dart.dart' show Db;

class DBConnection {
  static DBConnection? _instance;

  final String _host = "10.0.2.2";
  final String _port = "27017";
  final String _dbName = "tbcontrol";
  late Db _db;

  DBConnection._();

  static DBConnection getInstance() {
    _instance ??= DBConnection._();
    return _instance!;
  }

  Future<void> initialize() async {
    try {
      _db = Db(_getConnectionString());
      await _db.open();
    } catch (e) {
      print(e);
    }
  }

  Future<Db> getConnection() async {
    if (_db == null || !_db.isConnected) {
      await initialize();
    }
    return _db;
  }

  String _getConnectionString() {
    return "mongodb://$_host:$_port/$_dbName";
  }

  closeConnection() {
    _db.close();
  }
}
