class ArrowNode {
  final String arrowId;
  final Set<String> blockedBy;

  ArrowNode(this.arrowId, this.blockedBy);

  String getArrowId() => arrowId;

  bool isActivatable() => blockedBy.isEmpty;

  void removeBlocker(String blockerId) {
    blockedBy.remove(blockerId);
  }

  Set<String> getBlockers() => blockedBy;
}
