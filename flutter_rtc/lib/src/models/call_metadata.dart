import 'package:equatable/equatable.dart';

class CallUser with EquatableMixin {
  const CallUser({
    required this.id,
    required this.name,
    required this.roles,
    required this.image,
    this.custom = const {},
    this.teams = const [],
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final List<String> roles;
  final String image;
  final Map<String, Object?> custom;
  final List<String> teams;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  @override
  List<Object?> get props => [
        id,
        name,
        roles,
        image,
        teams,
        createdAt,
        updatedAt,
        deletedAt,
        custom,
      ];

  @override
  String toString() {
    return 'CallUser{'
        'id: $id'
        ', name: $name'
        ', role: $roles'
        ', image: $image'
        ', teams: $teams'
        ', createdAt: $createdAt'
        ', updatedAt: $updatedAt'
        ', deletedAt: $deletedAt'
        ', custom: $custom'
        '}';
  }
}
