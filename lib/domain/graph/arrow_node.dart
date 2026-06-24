class ArrowNode {
  final String arrowId;
  final Set<String> blockedBy;

  ArrowNode({required this.arrowId, required this.blockedBy});

  bool isActivatable() => blockedBy.isEmpty;

  void removeBlocker(String blockerId) => blockedBy.remove(blockerId);

  Set<String> getBlockers() => blockedBy;

  @override
  String toString() => 'ArrowNode($arrowId, blockedBy: ${blockedBy.length})';
}
