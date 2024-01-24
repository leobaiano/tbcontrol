import 'package:mongo_dart/mongo_dart.dart' as mongo_dart;

class UserData {
  final mongo_dart.ObjectId id;
  final String usuario;
  final String nome;
  final String cargo;

  UserData({
    required this.id,
    required this.usuario,
    required this.nome,
    required this.cargo,
  });
}
