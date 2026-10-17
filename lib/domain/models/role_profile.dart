class RoleProfile {
  RoleProfile({
    required this.id,
    required this.name,
    this.avatar,
    this.model = '',
    this.apiId,
    this.identity = '',
    this.soul = '',
    this.memory = '',
    this.archived = false,
    this.timezone = 'UTC',
    this.checkMin = 5,
    this.checkMax = 30,
    this.maxToolRounds = 8,
    this.defaultActivationProbability = 50,
    this.lockSoul = false,
    this.lockMemory = false,
    List<String>? lockedSchedules,
    List<Map<String, String>>? examples,
  }) : examples = examples ?? [],
       lockedSchedules = lockedSchedules ?? [];
  final String id;
  bool archived, lockSoul, lockMemory;
  String timezone;
  int checkMin, checkMax, maxToolRounds;
  double defaultActivationProbability;
  List<String> lockedSchedules;
  String name, model, identity, soul, memory;
  String? apiId, avatar;
  List<Map<String, String>> examples;
}
