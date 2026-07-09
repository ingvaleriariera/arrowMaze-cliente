class ArrowNode {
  final String arrowId;
  final Set<String> blockedBy;
  bool blockedByVoidReentry;

  ArrowNode({required this.arrowId, required this.blockedBy, this.blockedByVoidReentry = false});

  bool isActivatable() => blockedBy.isEmpty;

  void removeBlocker(String blockerId) => blockedBy.remove(blockerId);

  Set<String> getBlockers() => blockedBy;

  @override
  String toString() => 'ArrowNode($arrowId, blockedBy: ${blockedBy.length})';
}
